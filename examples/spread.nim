import std/strformat
import glm
import ../src/spread


proc test* =
  let num = 1'u8
  let a = [
    vec3f(10, 20, 30),
    vec3f(10, 20, 30),
    vec3f(10, 20, 30),
  ]
  let b = [
    vec4f(10, 20, 30, 40),
    vec4f(10, 20, 30, 40),
    vec4f(10, 20, 30, 40),
  ]
  
  proc returnVec4f: auto = vec4f(100, 200, 300, 400)
  proc returnInt: auto = 0

  let spreadedArray = ...(
    a[0], b[0], returnInt(), num.float32,
    a[1], b[1], returnVec4f(), vec4f(-1, -2, -3, -4),
    a[2], b[2],
  )
  echo &"{$typeof(spreadedArray)}\n{$spreadedArray}"

  let spreadedSeq = ...@(
    a[0], b[0], returnInt(), num.float32,
    a[1], b[1], returnVec4f(), vec4f(-1, -2, -3, -4),
    a[2], b[2],
  )
  echo &"{$typeof(spreadedSeq)}\n{$spreadedSeq}"