import std/macros
import std/strutils
import macroutils
import spread

{.experimental: "codeReordering".}


setCustomSpreadProc(spreadProc)


proc spreadProc(typeInst: NimNode, typeName: string, node, letSection, bracketExpr: NimNode) =
  # spread glm/Vec
  if typeName.startsWith "Vec":
    spreadVec(node, letSection, bracketExpr)
    return


proc spreadVec(node, letSection, bracketExpr: NimNode) =
  let sym = node[0]
  let impl = node.getTypeImpl()
  let max = impl[2][0][1][1][2].intVal
  case node.kind
  of nnkCall:
    let letSym = newLetSym(letSection, node)
    for i in 0 .. max:
      bracketExpr.add quote do: `letSym`.arr[`i`]
  else:
    let idx = node[1][1]
    for i in 0 .. max:
      bracketExpr.add quote do: `sym`[`idx`].arr[`i`]
