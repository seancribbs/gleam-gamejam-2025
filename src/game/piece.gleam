import game/core
import gleam_community/colour

pub fn piece_color(piece: core.PieceKind) -> Int {
  case piece {
    core.P1 -> colour.pink
    core.P2 -> colour.blue
    core.P3 -> colour.white
    core.P4 -> colour.light_orange
    core.P5 -> colour.yellow
  }
  |> colour.to_rgb_hex
}
