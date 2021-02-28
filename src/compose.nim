import std/macros
import std/strformat


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


# put this pragma on desired field
template use* {.pragma.}


# alias
template `@=`(name, v: untyped) {.dirty.} =
  template name: auto = v


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
  objTy.expectKind(nnkObjectTy)
  objTy


iterator getFieldsIter(ty: NimNode): tuple[field, fieldType: NimNode] =
  var objTy = ty.getObjImpl
  for f in objTy[2]:
    let ftyIndex = f.len - 2
    for i in 0 ..< ftyIndex:
      yield (f[i], f[ftyIndex])


iterator getFields(ty: NimNode): FieldInfo =
  for field, fieldType in getFieldsIter(ty):
    case field.kind
    of nnkIdent:
      yield (field, fieldType, false)
    of nnkPostfix:
      yield (field[1], fieldType, true)
    else:
      error("it's not a field!", field)


proc getUsedFields(ty: NimNode): FieldInfos =
  for field, fieldType in getFieldsIter(ty):
    if field.kind == nnkPragmaExpr:
      for p in field[1]:
        if p.strVal != "use": continue
        case field[0].kind
        of nnkIdent:
          result.add (field[0], fieldType, false)
        of nnkPostfix:
          result.add (field[0][1], fieldType, true)
        else:
          error("It's not a field!", field)


iterator findDupTypes(s: FieldInfos, idx: Natural): Natural =
  var v = s[idx]
  for i, f in s:
    if i == idx: continue
    if eqIdent(f.fieldType, v.fieldType):
      yield i


iterator findDupNames(s: FieldDetails, fIdx, dIdx:Natural): tuple[fieldIdx, detailIdx: int] =
  let v = s[fIdx].details[dIdx]
  for fi, f in s:
    var di = 0
    while di < f.details.len:
      if (fi, di) == (fIdx, dIdx):
        inc di
        continue
      d @= f.details[di]
      if eqIdent(d.fieldName, v.fieldName):
        yield (fi, di)
      else:
        inc di


proc hint_ambiguous(name, node: NimNode) {.used.} =
  when not defined(hideComposeHint):
    hint(&"Will not generate getter & setter for \"{name.repr}\" because it is ambiguous!"
, node)


macro compose*(t: typedesc) =
  var uniqueFields: FieldDetails
  
  # remove duplicate types
  block:
    var usedFields = t.getUsedFields()
    var i = 0
    while i in 0 .. usedFields.high:
      fname @= usedFields[i].fieldName
      ftype @= usedFields[i].fieldType
      var dupFound = false
      for dupi in usedFields.findDupTypes(i):
        dupFound = true
        dupName @= usedFields[dupi].fieldName
        dupType @= usedFields[dupi].fieldType
        hint_ambiguous(dupName, dupType)
        usedFields.del dupi
      if dupFound:
        hint_ambiguous(fname, ftype)
        usedFields.del i
      else:
        var details: FieldInfos
        for detail in ftype.getFields():
          details &= detail
        uniqueFields &= (usedFields[i], details)
        inc i
  
  # remove duplicate names
  for fi, f in uniqueFields.mpairs:
    var di = 0
    while di in 0 .. f.details.high:
      var dupFound = false
      for dupfi, dupdi in uniqueFields.findDupNames(fi, di):
        dupFound = true
        dupDetails @= uniqueFields[dupfi].details
        dupName @= dupDetails[dupdi].fieldName
        hint_ambiguous(dupName, dupName)
        dupDetails.del dupdi
      if dupFound:
        fname @= f.details[di].fieldName
        hint_ambiguous(fname, fname)
        f.details.del di
      else:
        inc di
  
  # generate getters and setters
  result = newStmtList()
  let self = ident "self"
  let val = ident "val"
  # defer: echo result.repr
  for f in uniqueFields:
    let fname = f.field.fieldName
    for (name, ty, exported) in f.details:
      var getter = name
      var setter = newTree(nnkAccQuoted, name, ident "=")
      if exported:
        getter = getter.postfix("*")
        setter = setter.postfix("*")
      result.add quote do:
        template `getter`(`self`: `t`): `ty` {.used.} = `self`.`fname`.`name`
        template `getter`(`self`: var `t`): var `ty` {.used.} = `self`.`fname`.`name`
        template `setter`(`self`: var `t`, `val`:`ty`) {.used.} = `self`.`fname`.`name` = `val`
