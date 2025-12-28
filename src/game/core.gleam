import easings
import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/time/duration
import tiramisu/tween

const piece_exit_duration: Int = 100

pub type Piece {
  Piece(kind: PieceKind, id: Int)
}

pub type PieceKind {
  P1
  P2
  P3
  P4
  P5
}

pub type BoardState {
  Playing
  Failed
}

pub type Board {
  Board(
    next_piece_id: Int,
    state: BoardState,
    pieces: Rings,
    patterns: Rings,
    selected: RingName,
    transitions: Transitions,
  )
}

pub type Transitions =
  dict.Dict(Entity, Transition)

pub type Rings {
  Rings(inner: Ring, middle: Ring, outer: Ring)
}

pub fn new_board() -> Board {
  Board(
    next_piece_id: 4,
    state: Playing,
    pieces: new_rings(),
    patterns: new_rings(),
    selected: Inner,
    transitions: dict.from_list([
      #(RingEntity(Outer), RotateRing(direction: Right, tween: rotate_tween())),
    ]),
  )
}

fn rotate_tween() -> tween.Tween(Float) {
  tween.tween_float(0.0, 1.0, duration.seconds(3), easings.linear)
}

pub fn new_rings() -> Rings {
  Rings(inner: new_ring(1), middle: new_ring(2), outer: new_ring(3))
}

pub fn new_ring(id: Int) -> Ring {
  let kind = case id % 5 {
    1 -> P1
    2 -> P2
    3 -> P3
    _ -> P4
  }
  Ring(
    a: None,
    b: Some(Piece(id:, kind:)),
    c: None,
    d: None,
    e: None,
    f: None,
    g: None,
    h: None,
  )
}

pub type RingName {
  Inner
  Middle
  Outer
}

pub type Entity {
  PieceEntity(Int)
  RingEntity(RingName)
}

pub type Transition {
  RotateRing(direction: RingRotation, tween: tween.Tween(Float))
  PieceExit(position: #(RingName, Int), tween: tween.Tween(Float))
  PieceDrop(tween: tween.Tween(Float))
  PieceFalling(position: Int, piece: Piece, tween: tween.Tween(Float))
}

pub type RingRotation {
  Left
  Right
}

type Slot =
  Option(Piece)

pub type Ring {
  Ring(a: Slot, b: Slot, c: Slot, d: Slot, e: Slot, f: Slot, g: Slot, h: Slot)
}

pub fn handle_tick(board: Board, delta_time: duration.Duration) -> Board {
  board
  |> advance_transitions(delta_time)
  |> queue_vertical_matches()
  |> queue_horizontal_matches()
  // |> queue_drops()
  |> apply_drops()
}

// Progress active transitions, purging them if they are complete and
// modifying the state as needed if they represent the completion of
// an action
fn advance_transitions(board: Board, delta_time: duration.Duration) -> Board {
  dict.fold(board.transitions, board, fn(board, entity, transition) {
    case transition {
      RotateRing(direction:, tween:) -> {
        let tween = tween.update(tween, delta_time)
        let #(pieces, transitions) = case tween.is_complete(tween) {
          // Just advance the transition
          False -> #(
            board.pieces,
            dict.insert(
              board.transitions,
              entity,
              RotateRing(direction:, tween:),
            ),
          )

          // Complete the ring rotation and remove the transition
          True -> {
            let assert RingEntity(r) = entity
            let pieces = case r {
              Inner ->
                Rings(
                  ..board.pieces,
                  inner: rotate_ring(board.pieces.inner, direction),
                )
              Middle ->
                Rings(
                  ..board.pieces,
                  middle: rotate_ring(board.pieces.middle, direction),
                )
              Outer ->
                Rings(
                  ..board.pieces,
                  outer: rotate_ring(board.pieces.outer, direction),
                )
            }
            #(pieces, dict.delete(board.transitions, entity))
          }
        }
        Board(..board, pieces:, transitions:)
      }
      PieceExit(position:, tween:) -> {
        let tween = tween.update(tween, delta_time)
        let #(pieces, transitions) = case tween.is_complete(tween) {
          // Just advance the transition
          False -> #(
            board.pieces,
            dict.insert(board.transitions, entity, PieceExit(position:, tween:)),
          )

          // Remove the piece from the board and clear the transition
          True -> {
            let #(ring, slot) = position
            let pieces = case ring {
              Inner ->
                Rings(
                  ..board.pieces,
                  inner: clear_piece(board.pieces.inner, slot),
                )
              Middle ->
                Rings(
                  ..board.pieces,
                  middle: clear_piece(board.pieces.middle, slot),
                )
              Outer ->
                Rings(
                  ..board.pieces,
                  outer: clear_piece(board.pieces.outer, slot),
                )
            }
            #(pieces, dict.delete(board.transitions, entity))
          }
        }
        Board(..board, pieces:, transitions:)
      }
      PieceDrop(tween:) -> {
        let tween = tween.update(tween, delta_time)
        let transitions = case tween.is_complete(tween) {
          False -> dict.insert(board.transitions, entity, PieceDrop(tween:))
          True -> dict.delete(board.transitions, entity)
        }
        Board(..board, transitions:)
      }
      PieceFalling(position:, piece:, tween:) as pf -> {
        let tween = tween.update(tween, delta_time)
        let #(state, outer, transitions) = case tween.is_complete(tween) {
          False -> #(
            board.state,
            board.pieces.outer,
            dict.insert(board.transitions, entity, PieceFalling(..pf, tween:)),
          )
          True -> {
            case place_piece(board.pieces.outer, position, piece) {
              Ok(outer) -> #(
                board.state,
                outer,
                dict.delete(board.transitions, entity),
              )
              Error(_) -> #(
                Failed,
                board.pieces.outer,
                dict.delete(board.transitions, entity),
              )
            }
          }
        }
        Board(
          ..board,
          state:,
          pieces: Rings(..board.pieces, outer:),
          transitions:,
        )
      }
    }
  })
}

fn rotate_ring(ring: Ring, direction: RingRotation) -> Ring {
  case direction {
    Left -> rotate_left(ring)
    Right -> rotate_right(ring)
  }
}

// Rotates a ring (ring) to the left one slot by shifting all of its
// pieces
fn rotate_left(ring: Ring) -> Ring {
  Ring(
    a: ring.b,
    b: ring.c,
    c: ring.d,
    d: ring.e,
    e: ring.f,
    f: ring.g,
    g: ring.h,
    h: ring.a,
  )
}

// Rotates a ring (ring) to the right one slot by shifting all
// of its pieces
pub fn rotate_right(ring: Ring) -> Ring {
  Ring(
    a: ring.h,
    b: ring.a,
    c: ring.b,
    d: ring.c,
    e: ring.d,
    f: ring.e,
    g: ring.f,
    h: ring.g,
  )
}

// Determines whether a given pattern matches a ring on the board
// by comparing all the desired slots with the actual pieces
pub fn pattern_matches_ring(pattern: Ring, ring: Ring) -> Bool {
  pattern_matches(pattern.a, ring.a)
  && pattern_matches(pattern.b, ring.b)
  && pattern_matches(pattern.c, ring.c)
  && pattern_matches(pattern.d, ring.d)
  && pattern_matches(pattern.e, ring.e)
  && pattern_matches(pattern.f, ring.f)
  && pattern_matches(pattern.g, ring.g)
  && pattern_matches(pattern.h, ring.h)
}

fn pattern_matches(pattern: Slot, piece: Slot) -> Bool {
  case pattern, piece {
    None, _ -> True
    Some(p), Some(r) -> p.kind == r.kind
    _, _ -> False
  }
}

// Did the puzzle pattern get solved? Equivalent to all
// rings match their given patterns.
pub fn board_solved(board: Board) -> Bool {
  pattern_matches_ring(board.patterns.inner, board.pieces.inner)
  && pattern_matches_ring(board.patterns.middle, board.pieces.middle)
  && pattern_matches_ring(board.patterns.outer, board.pieces.outer)
}

// Ensure pieces above holes are dropped into the ring below
pub fn apply_drops(board: Board) -> Board {
  let Rings(inner:, middle:, outer:) = board.pieces
  let #(middle, inner) = execute_drop(middle, inner)
  let #(outer, middle) = execute_drop(outer, middle)
  Board(..board, pieces: Rings(inner:, middle:, outer:))
}

// Drop pieces from the ring above into the holes below
fn execute_drop(above: Ring, below: Ring) -> #(Ring, Ring) {
  #(
    Ring(
      a: execute_drop_above(above.a, below.a),
      b: execute_drop_above(above.b, below.b),
      c: execute_drop_above(above.c, below.c),
      d: execute_drop_above(above.d, below.d),
      e: execute_drop_above(above.e, below.e),
      f: execute_drop_above(above.f, below.f),
      g: execute_drop_above(above.g, below.g),
      h: execute_drop_above(above.h, below.h),
    ),
    Ring(
      a: execute_drop_below(above.a, below.a),
      b: execute_drop_below(above.b, below.b),
      c: execute_drop_below(above.c, below.c),
      d: execute_drop_below(above.d, below.d),
      e: execute_drop_below(above.e, below.e),
      f: execute_drop_below(above.f, below.f),
      g: execute_drop_below(above.g, below.g),
      h: execute_drop_below(above.h, below.h),
    ),
  )
}

fn execute_drop_above(above: Slot, below: Slot) -> Slot {
  // can't drop if occupied
  case below {
    Some(_) -> above
    None -> None
  }
}

fn execute_drop_below(above: Slot, below: Slot) -> Slot {
  // allow drop if unoccupied
  case below {
    Some(_) -> below
    None -> above
  }
}

// Tries to place a piece into the given slot in a ring, returning an error if
// occupied
fn place_piece(ring: Ring, position: Int, piece: Piece) -> Result(Ring, Nil) {
  let Ring(a, b, c, d, e, f, g, h) = ring
  let piece_on_board = Some(piece)
  case position {
    0 if a == None -> Ok(Ring(..ring, a: piece_on_board))
    1 if b == None -> Ok(Ring(..ring, b: piece_on_board))
    2 if c == None -> Ok(Ring(..ring, c: piece_on_board))
    3 if d == None -> Ok(Ring(..ring, d: piece_on_board))
    4 if e == None -> Ok(Ring(..ring, e: piece_on_board))
    5 if f == None -> Ok(Ring(..ring, f: piece_on_board))
    6 if g == None -> Ok(Ring(..ring, g: piece_on_board))
    7 if h == None -> Ok(Ring(..ring, h: piece_on_board))
    _ -> Error(Nil)
  }
}

// Clears the slot in a ring in the given position, setting it to None
fn clear_piece(ring: Ring, position: Int) -> Ring {
  case position {
    0 -> Ring(..ring, a: None)
    1 -> Ring(..ring, b: None)
    2 -> Ring(..ring, c: None)
    3 -> Ring(..ring, d: None)
    4 -> Ring(..ring, e: None)
    5 -> Ring(..ring, f: None)
    6 -> Ring(..ring, g: None)
    7 -> Ring(..ring, h: None)
    _ -> panic as "invalid slot"
  }
}

// 1. Discover vertical matches (3 pieces)
//    by column: if all three pieces have the same type -> queue PieceExit transition
fn queue_vertical_matches(board: Board) -> Board {
  let Rings(inner:, middle:, outer:) = board.pieces
  let transitions =
    [
      vertical_match(0, inner.a, middle.a, outer.a),
      vertical_match(1, inner.b, middle.b, outer.b),
      vertical_match(2, inner.c, middle.c, outer.c),
      vertical_match(3, inner.d, middle.d, outer.d),
      vertical_match(4, inner.e, middle.e, outer.e),
      vertical_match(5, inner.f, middle.f, outer.f),
      vertical_match(6, inner.g, middle.g, outer.g),
      vertical_match(7, inner.h, middle.h, outer.h),
    ]
    |> list.fold(dict.new(), dict.merge)
    |> dict.merge(board.transitions)
  // Ensures existing transitions aren't overwritten/reset

  Board(..board, transitions:)
}

fn vertical_match(
  position: Int,
  inner: Slot,
  middle: Slot,
  outer: Slot,
) -> Transitions {
  case inner, middle, outer {
    Some(Piece(kind: ikind, id: iid)),
      Some(Piece(kind: mkind, id: mid)),
      Some(Piece(kind: okind, id: oid))
      if ikind == mkind && ikind == okind
    -> {
      dict.from_list([
        #(PieceEntity(iid), piece_exit_transition(Inner, position)),
        #(PieceEntity(mid), piece_exit_transition(Middle, position)),
        #(PieceEntity(oid), piece_exit_transition(Outer, position)),
      ])
    }
    _, _, _ -> dict.new()
  }
}

pub fn piece_exit_transition(ring_name: RingName, position: Int) -> Transition {
  PieceExit(
    position: #(ring_name, position),
    tween: tween.tween_float(
      1.0,
      0.0,
      duration.milliseconds(piece_exit_duration),
      easings.back_in,
    ),
  )
}

// 2. Discover horizontal matches (3..5 pieces)
pub fn queue_horizontal_matches(board: Board) -> Board {
  let Rings(inner:, middle:, outer:) = board.pieces
  let transitions =
    [
      queue_horizontal_matches_ring(Inner, inner),
      queue_horizontal_matches_ring(Middle, middle),
      queue_horizontal_matches_ring(Outer, outer),
    ]
    |> list.fold(dict.new(), dict.merge)
    |> dict.merge(board.transitions)

  Board(..board, transitions:)
}

pub fn queue_horizontal_matches_ring(
  ring_name: RingName,
  ring: Ring,
) -> Transitions {
  list.fold(
    [
      horizontal_matches(ring_name, ring, 5),
      horizontal_matches(ring_name, ring, 4),
      horizontal_matches(ring_name, ring, 3),
    ],
    dict.new(),
    dict.merge,
  )
}

pub fn horizontal_matches(
  ring_name: RingName,
  ring: Ring,
  count: Int,
) -> Transitions {
  list.range(0, 7)
  |> list.filter_map(fn(i) {
    horizontal_pieces_match(ring, i, count)
    |> result.map(horizontal_piece_transitions(_, i, ring_name))
  })
  |> list.fold(dict.new(), dict.merge)
}

pub fn horizontal_piece_transitions(
  pieces: List(Piece),
  start: Int,
  ring_name: RingName,
) -> Transitions {
  pieces
  |> list.fold(#(start, []), fn(acc, piece) {
    let #(index, items) = acc
    #(index + 1, [
      #(PieceEntity(piece.id), piece_exit_transition(ring_name, index % 8)),
      ..items
    ])
  })
  |> pair.second
  |> dict.from_list()
}

pub fn horizontal_pieces_match(
  ring: Ring,
  start: Int,
  count: Int,
) -> Result(List(Piece), Nil) {
  case piece_at(ring, start) {
    None -> Error(Nil)
    Some(first) -> {
      start + 1
      |> list.range(start + count - 1)
      |> list.try_fold([first], fn(acc, index) {
        let assert [prev, ..] = acc
        case piece_at(ring, index) {
          Some(piece) if piece.kind == prev.kind -> Ok([piece, ..acc])
          _ -> Error(Nil)
        }
      })
      |> result.map(list.reverse)
    }
  }
}

pub fn piece_at(ring: Ring, position: Int) -> Slot {
  case position % 8 {
    0 -> ring.a
    1 -> ring.b
    2 -> ring.c
    3 -> ring.d
    4 -> ring.e
    5 -> ring.f
    6 -> ring.g
    7 -> ring.h
    _ -> None
  }
}
