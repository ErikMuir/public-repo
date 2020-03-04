case class Axis(symbol: String)
case class Face(symbol: String, axis: Axis)
case class Direction(symbol: String)
case class Turn(face: Face, direction: Direction) {
  override def toString(): String = s"${face.symbol}${direction.symbol}"
}

val xAxis: Axis = Axis("X")
val yAxis: Axis = Axis("Y")
val zAxis: Axis = Axis("Z")

val up: Face = Face("U", yAxis)
val down: Face = Face("D", yAxis)
val left: Face = Face("L", xAxis)
val right: Face = Face("R", xAxis)
val front: Face = Face("F", zAxis)
val back: Face = Face("B", zAxis)

val clockwise: Direction = Direction("")
val counterClockwise: Direction = Direction("'")
val double: Direction = Direction("2")

val faces = Array(up, down, left, right, front, back)
val directions = Array(clockwise, counterClockwise, double)

class TurnGenerator(val len: Int = 20) extends Iterator[String] {
  private var _previousAxis: Axis = _
  private var _current = 0

  def hasNext: Boolean = { _current < len }

  def next() = {
    if(hasNext) {
      _current += 1
      Turn(getRandomFace(), getRandomDirection()).toString()
    } else ""
  }
  
  private def getRandomFace(): Face = {
    val availableFaces = faces.filter(f => f.axis != _previousAxis)
    availableFaces((Math.random * availableFaces.length).toInt)
  }
  
  private def getRandomDirection(): Direction = {
    directions((Math.random * directions.length).toInt)
  }
}

try {
  val turnCount = if (args.length > 0) args(0).toInt else 20
  val sequence = new TurnGenerator(turnCount).mkString(" ")
  println(sequence)
} catch {
  case _: Throwable =>
    {
      println ("you fail")
    System.exit (1)
  }
}
