import std/macros
import std/algorithm


type
  FieldInfo = tuple
    fieldName: NimNode
    fieldType: NimNode
    exported: bool
  
  FieldDetail = tuple
    field: FieldInfo
    details: FieldInfos

  FieldInfos = seq[FieldInfo]
  FieldDetails = seq[FieldDetail]


template use* {.pragma.}


proc removeAt[T](list: var seq[T], indices: openArray[int]) =
  # indices must be ordered
  for i in indices.reversed:
    list.del i


proc findDupType(s: FieldInfos, v: NimNode, currentName: NimNode): seq[int] =
  for i, f in s:
    if eqIdent(f.fieldName, currentName): continue
    if eqIdent(f.fieldType, v): result.add i


proc findDupName(s: FieldDetails, v: NimNode, current: FieldDetail): seq[tuple[fieldIdx, detailIdx: int]] =
  for i_field, f in s:
    if f == current: continue
    for i_detail, d in f.details:
      if eqIdent(d.fieldName, v):
        result.add (i_field, i_detail)


template getObjImpl(ty: untyped): NimNode =
  if ty.kind == nnkBracketExpr:
    error("generics are not suppported! (sorry...)", ty)
  
  if ty.kind != nnkSym:
    error("only object is allowed!", ty)
  
  let impl = ty.getImpl()
  if impl.kind == nnkNilLit:
    error("only object is allowed!", ty)

  var objTy = impl[2]
  if objTy.kind in {nnkRefTy, nnkPtrTy}:
    objTy = objTy[0] # Unwrap ref/ptr types
  objTy.expectKind(nnkObjectTy) # Check that the type is actually an object
  objTy


template getFieldsTemplate(ty: NimNode, body: untyped) =
  var objTy = ty.getObjImpl
  for f in objTy[2]:
    let ftyIndex = f.len - 2
    let fieldType {.inject.} = f[ftyIndex]
    for i in 0 ..< ftyIndex:
      template field: auto {.inject.} = f[i]
      body


iterator getFields(ty: NimNode): tuple[name, ty: NimNode, exported: bool] =
  getFieldsTemplate(ty):
    case field.kind
    of nnkIdent:
      yield (field, fieldType, false)
    of nnkPostfix:
      yield (field[1], fieldType, true)
    else:
      error("it's not a field!", field)


proc getUsedFields(ty: NimNode): FieldInfos =
  getFieldsTemplate(ty):
    if field.kind == nnkPragmaExpr:
      for p in field[1]:
        if p.strVal != "use": continue # check pragma
        case field[0].kind
        of nnkIdent:
          result.add (field[0], fieldType, false)
        of nnkPostfix:
          result.add (field[0][1], fieldType, true)
        else:
          error("it's not a field!", field)


template msg_ambiguous(x: untyped): string {.used.} =
  "Will not generate getter & setter for \"" & x.repr & "\" because it is ambiguous!"


macro compose*(t: typedesc) =
  result = newStmtList()
  var uniqueFields: FieldDetails
  
  # remove duplicate types
  block:
    var usedFields = t.getUsedFields()
    var i = 0
    while i > -1 and i < usedFields.len:
      let (name, ty, _) = usedFields[i]
      let dups = usedFields.findDupType(ty, name)
      if dups.len == 0:
        var details: FieldInfos
        for name, ty, exported in ty.getFields():
          details.add (name, ty, exported)
        uniqueFields.add (usedFields[i], details)
        inc i
        continue
      when not defined(hideComposeHint):
        hint(msg_ambiguous(name), ty)
        for idx in dups:
          hint(msg_ambiguous(usedFields[idx].fieldName), usedFields[idx].fieldType)
      usedFields.removeAt(i & dups);
      if i == usedFields.len: dec i
  
  # remove duplicate names
  for f in uniqueFields.mitems:
    var i = 0
    while i > -1 and i < f.details.len:
      let dups = uniqueFields.findDupName(f.details[i].fieldName, f)
      if dups.len == 0:
        inc i
        continue
      when not defined(hideComposeHint):
        hint(msg_ambiguous(f.details[i].fieldName), f.field.fieldName)
      f.details.del i
      if i == f.details.len: dec i
      for (i_field, i_detail) in dups:
        template dupField: auto = uniqueFields[i_field]
        when not defined(hideComposeHint):
          hint(msg_ambiguous(dupField.details[i_detail].fieldName), dupField.field.fieldName)
        dupField.details.del i_detail
  
  # generate getters and setters
  # defer: echo result.repr
  let self = ident "self"
  let val = ident "val"
  for f in uniqueFields:
    let fname = f.field.fieldName
    for (name, ty, exported) in f.details:
      var getter = name
      var setter = nnkAccQuoted.newTree(name, ident "=")
      if exported:
        getter = getter.postfix("*")
        setter = setter.postfix("*")
      result.add quote do:
        template `getter`(`self`: `t`): `ty` {.used.} = `self`.`fname`.`name`
        template `getter`(`self`: var `t`): var `ty` {.used.} = `self`.`fname`.`name`
        template `setter`(`self`: var `t`, `val`:`ty`) {.used.} = `self`.`fname`.`name` = `val`
