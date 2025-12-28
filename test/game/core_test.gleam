import game/core.{Inner, P1, Piece, PieceEntity, PieceExit, Ring}
import gleam/dict
import gleam/option.{None, Some}

pub fn horizontal_pieces_match_test() {
  let ring =
    Ring(
      a: Some(Piece(id: 1, kind: P1)),
      b: Some(Piece(id: 2, kind: P1)),
      c: None,
      d: None,
      e: None,
      f: Some(Piece(id: 3, kind: P1)),
      g: Some(Piece(id: 4, kind: P1)),
      h: Some(Piece(id: 5, kind: P1)),
    )
  assert Ok([
      Piece(id: 3, kind: P1),
      Piece(id: 4, kind: P1),
      Piece(id: 5, kind: P1),
      Piece(id: 1, kind: P1),
      Piece(id: 2, kind: P1),
    ])
    == core.horizontal_pieces_match(ring, 5, 5)

  assert Ok([
      Piece(id: 3, kind: P1),
      Piece(id: 4, kind: P1),
      Piece(id: 5, kind: P1),
      Piece(id: 1, kind: P1),
    ])
    == core.horizontal_pieces_match(ring, 5, 4)

  assert Ok([
      Piece(id: 3, kind: P1),
      Piece(id: 4, kind: P1),
      Piece(id: 5, kind: P1),
    ])
    == core.horizontal_pieces_match(ring, 5, 3)

  assert Error(Nil) == core.horizontal_pieces_match(ring, 0, 3)
}

pub fn horizontal_piece_transitions_test() {
  let t =
    core.horizontal_piece_transitions(
      [
        Piece(id: 3, kind: P1),
        Piece(id: 4, kind: P1),
        Piece(id: 5, kind: P1),
        Piece(id: 1, kind: P1),
        Piece(id: 2, kind: P1),
      ],
      5,
      Inner,
    )

  let assert Ok(PieceExit(position: #(Inner, 5), ..)) =
    dict.get(t, PieceEntity(3))
  let assert Ok(PieceExit(position: #(Inner, 6), ..)) =
    dict.get(t, PieceEntity(4))
  let assert Ok(PieceExit(position: #(Inner, 7), ..)) =
    dict.get(t, PieceEntity(5))
  let assert Ok(PieceExit(position: #(Inner, 0), ..)) =
    dict.get(t, PieceEntity(1))
  let assert Ok(PieceExit(position: #(Inner, 1), ..)) =
    dict.get(t, PieceEntity(2))
}
