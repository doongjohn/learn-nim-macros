import ../src/compose


type 
  Creature = object
    name: string
    age: int
    x: int
  
  Vector2 = object
    x: float
    y: float
  
  Data = object
    x: int
  
  Player = object
    creature {.use.}: Creature
    position {.use.}: Vector2
    data {.use.}: Data


proc test* =
  compose Player

  echo "-------------------"
  var p: Player
  
  p.name = "John"
  p.age = 5
  echo "    name: " & $p.name
  echo "     age: " & $p.age
  
  p.creature.name = "Mike"
  p.creature.age = 12
  echo "    name: " & $p.name
  echo "     age: " & $p.age
  
  p.position = Vector2(x: 2.0, y: 2.0)
  echo "position: " & $(p.position.x, p.y)
  
  echo "-------------------"