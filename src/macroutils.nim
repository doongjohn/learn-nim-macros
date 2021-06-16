import std/macros


template `@=`*(name, value: untyped) {.dirty.} =
  # create alias
  template name: typeof(value) = value


template newLetSym*(letSection, rhs: NimNode): NimNode =
  let sym = genSym(nskLet)
  letSection.add newNimNode(nnkIdentDefs)
  letSection.last.add sym
  letSection.last.add newEmptyNode()
  letSection.last.add rhs
  sym


macro invoke*(v: string, args: varargs[NimNode]): untyped =
  result = newNimNode(nnkCall)
  result.add newIdentNode(v.strVal)
  for arg in args:
    result.add arg
