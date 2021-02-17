import std/macros


template newLetSym*(letSection, rhs: NimNode): NimNode =
  let sym = genSym(nskLet, "tmp_let")
  letSection.add newNimNode(nnkIdentDefs)
  letSection.last.add sym
  letSection.last.add newEmptyNode()
  letSection.last.add rhs
  sym


macro callByName*(v: string, args: varargs[NimNode]): untyped =
  result = newNimNode(nnkCall)
  result.add newIdentNode("spread" & v.strVal)
  for arg in args:
    result.add arg