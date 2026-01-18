import game/core.{type RingName}
import gleam/int
import tiramisu/scene
import tiramisu/transform

pub type Id {
  RootScene
  RootCamera
  Background
  Lights
  Light(Int)
  Debug(Int)
  BoardGroup
  BoardRing(RingName)
  RingPieces(RingName)
  RingPatterns(RingName)
  Pattern(RingName, Int)
  Piece(Int)
  Overlay
  OverlayMask
}

pub fn id(id: Id) -> String {
  case id {
    RootScene -> "root"
    RootCamera -> "main-camera"
    Background -> "background"
    Lights -> "lights"
    Light(i) -> "light-" <> int.to_string(i)
    Debug(i) -> "debug-" <> int.to_string(i)
    BoardGroup -> "board"
    BoardRing(name) -> "ring-" <> ring_name_to_string(name)
    RingPieces(name) -> "pieces-" <> ring_name_to_string(name)
    Piece(i) -> "piece-" <> int.to_string(i)
    Overlay -> "overlay"
    OverlayMask -> "overlay-mask"
    RingPatterns(name) -> "patterns-" <> ring_name_to_string(name)
    Pattern(name, position) ->
      "pattern-" <> ring_name_to_string(name) <> "-" <> int.to_string(position)
  }
}

pub fn root_scene(children: List(scene.Node)) -> scene.Node {
  scene.empty(id: id(RootScene), transform: transform.identity, children:)
}

fn ring_name_to_string(name: RingName) -> String {
  case name {
    core.Inner -> "inner"
    core.Middle -> "middle"
    core.Outer -> "outer"
  }
}
