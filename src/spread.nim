import std/macros
import macroutils
import spreadProcs


const basicPrimitives = {
  ntyString, ntyCString,
  ntyUInt, ntyUInt8, ntyUInt16, ntyUInt32, ntyUInt64,
  ntyInt, ntyInt8, ntyInt16, ntyInt32, ntyInt64,
  ntyFloat, ntyFloat32, ntyFloat64, ntyFloat128
}


proc spread(node, letSection, bracketExpr: NimNode) =
  let typeInst = node.getTypeInst
  let strRepr = typeInst.strVal
  
  # spread literals
  if node.kind in nnkLiterals:
    bracketExpr.add quote do: `node`
    return
  
  # spread basic primitives
  if typeInst.typeKind in basicPrimitives:
    bracketExpr.add quote do: `node`
    return
  
  # spread glm/Vec
  # TODO: find a way to make it extensible
  if strRepr.high > 2 and strRepr[0 .. 2] == "Vec":
    callByName("Vec", node, letSection, bracketExpr)
    return


macro `...`*(args: varargs[typed]): untyped =
  result = newStmtList(newBlockStmt(newStmtList()))
  result[0][1].add newNimNode(nnkLetSection)
  result[0][1].add newNimNode(nnkBracket)
  var letSection = result[0][1][0]
  var bracketExpr = result[0][1][1]
  for node in args[0]:
    spread(node, letSection, bracketExpr)


macro `...@`*(args: varargs[typed]): untyped =
  result = newStmtList(newBlockStmt(newStmtList()))
  result[0][1].add newNimNode(nnkLetSection)
  result[0][1].add newNimNode(nnkPrefix)
  result[0][1][1].add ident("@")
  result[0][1][1].add newNimNode(nnkBracket)
  var letSection = result[0][1][0]
  var bracketExpr = result[0][1][1][1]
  for node in args[0]:
    spread(node, letSection, bracketExpr)
