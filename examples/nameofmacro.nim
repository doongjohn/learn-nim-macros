import ../src/nameofmacro


var a = 0
var b = "wow"

type T = object
  x: int
  y: proc()

var t = T()


proc test* =
  echo nameof nameofmacro
  echo nameof a
  echo nameof b
  echo nameof t.x
  echo nameof t.y
  echo nameof T
  echo nameof seq
  echo nameof newSeq
  echo nameof `+`
  echo nameof nameof

