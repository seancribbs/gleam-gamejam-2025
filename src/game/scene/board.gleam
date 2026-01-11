// import game/core
import game/core
import game/piece
import game/scene.{BoardGroup, BoardRing, Piece, RingPieces, id} as _
import game/state.{type GameState, InGame, Paused}
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/duration
import gleam_community/colour
import gleam_community/maths
import tiramisu/geometry
import tiramisu/material
import tiramisu/scene
import tiramisu/transform
import tiramisu/tween
import vec/vec3

pub fn board(
  state: GameState,
  board: core.Board,
  time: duration.Duration,
) -> scene.Node {
  scene.empty(
    id: id(BoardGroup),
    transform: transform.identity,
    children: case state {
      InGame | Paused ->
        list.flatten([
          rings(board.selected),
          pieces(board, time),
          falling_pieces(board, time),
        ])
      _ -> []
    },
  )
}

fn pieces(board: core.Board, time: duration.Duration) -> List(scene.Node) {
  let piece_geo = piece_geometry()
  let core.Rings(inner:, middle:, outer:) = board.pieces
  use r <- list.map([
    #(core.Inner, inner),
    #(core.Middle, middle),
    #(core.Outer, outer),
  ])

  let #(ring_name, ring) = r
  let pieces =
    list.filter_map(list.range(0, 7), fn(i) {
      case core.piece_at(ring, i) {
        None -> Error(Nil)
        Some(p) -> {
          let piece_mat = piece_material(p)

          let p_transform =
            piece_transform(
              Some(ring_name),
              i,
              time,
              dict.get(board.transitions, core.PieceEntity(p.id)),
            )

          Ok(scene.mesh(
            id: id(Piece(p.id)),
            transform: p_transform,
            geometry: piece_geo,
            material: piece_mat,
            physics: None,
          ))
        }
      }
    })

  let group_transform = case
    dict.get(board.transitions, core.RingEntity(ring_name))
  {
    Ok(core.RotateRing(direction:, tween:)) -> {
      let rotation_direction = case direction {
        // CCW but Z goes into the screen, so it's flipped
        core.Left -> -1.0
        // CW
        core.Right -> 1.0
      }

      transform.identity
      |> transform.rotate_z(
        { rotation_direction *. maths.pi() /. 4.0 } *. tween.get_value(tween),
      )
    }
    _ -> {
      transform.identity
    }
  }
  scene.empty(
    id: id(RingPieces(ring_name)),
    transform: group_transform,
    children: pieces,
  )
}

fn piece_geometry() -> geometry.Geometry {
  let assert Ok(piece_geo) = geometry.icosahedron(radius: 0.25, detail: 0)
  piece_geo
}

fn piece_material(p: core.Piece) -> material.Material {
  let assert Ok(piece_mat) =
    material.new()
    |> material.with_color(piece.piece_color(p.kind))
    |> material.with_metalness(0.75)
    |> material.with_roughness(0.5)
    |> material.build()
  piece_mat
}

fn piece_transform(
  ring_name: Option(core.RingName),
  position: Int,
  time: duration.Duration,
  transition: Result(core.Transition, Nil),
) -> transform.Transform {
  let distance = case ring_name, transition {
    Some(core.Inner), _ -> 1.5
    Some(core.Middle), _ -> 2.25
    Some(core.Outer), _ -> 3.0
    _, Ok(core.PieceFalling(tween:, ..)) ->
      5.0 -. { tween.get_value(tween) *. 2.0 }
    _, _ -> panic as "invalid piece transform arguments"
  }
  let time = duration.to_seconds(time)
  let angle = { maths.pi() /. 4.0 } *. int.to_float(position)
  let x = distance *. maths.cos(angle)
  let y = distance *. maths.sin(angle)

  // Scale up/down the piece when it is exiting the board
  let scale = case transition {
    Ok(core.PieceExit(tween:, ..)) ->
      tween |> tween.get_value() |> float.clamp(min: 0.0, max: 2.0)

    _ -> 1.0
  }
  transform.at(vec3.Vec3(x, y, 97.0))
  |> transform.rotate_y(time /. 1.0)
  |> transform.rotate_z(time /. 2.0)
  |> transform.rotate_x(time /. 5.0)
  |> transform.with_scale(vec3.splat(scale))
}

fn rings(selected: core.RingName) -> List(scene.Node) {
  let assert Ok(inner_geo) =
    geometry.torus(
      radius: 1.5,
      tube: 0.15,
      radial_segments: 4,
      tubular_segments: 60,
    )
  let assert Ok(middle_geo) =
    geometry.torus(
      radius: 2.25,
      tube: 0.15,
      radial_segments: 4,
      tubular_segments: 60,
    )
  let assert Ok(outer_geo) =
    geometry.torus(
      radius: 3.0,
      tube: 0.15,
      radial_segments: 4,
      tubular_segments: 60,
    )
  let assert Ok(ring_mat) =
    material.new()
    |> material.with_color(colour.to_rgb_hex(colour.light_blue))
    |> material.with_metalness(0.75)
    |> material.with_roughness(0.0)
    |> material.build()

  let assert Ok(selected_ring_mat) =
    material.new()
    |> material.with_color(colour.to_rgb_hex(colour.yellow))
    |> material.with_metalness(0.75)
    |> material.with_roughness(0.0)
    |> material.build()

  let transform = transform.at(vec3.Vec3(0.0, 0.0, 100.0))
  [
    scene.mesh(
      id: id(BoardRing(core.Inner)),
      transform:,
      geometry: inner_geo,
      material: case selected {
        core.Inner -> selected_ring_mat
        _ -> ring_mat
      },
      physics: None,
    ),
    scene.mesh(
      id: id(BoardRing(core.Middle)),
      transform:,
      geometry: middle_geo,
      material: case selected {
        core.Middle -> selected_ring_mat
        _ -> ring_mat
      },
      physics: None,
    ),
    scene.mesh(
      id: id(BoardRing(core.Outer)),
      transform:,
      geometry: outer_geo,
      material: case selected {
        core.Outer -> selected_ring_mat
        _ -> ring_mat
      },
      physics: None,
    ),
  ]
}

fn falling_pieces(
  board: core.Board,
  time: duration.Duration,
) -> List(scene.Node) {
  let piece_geo = piece_geometry()

  board.transitions
  |> dict.values()
  |> list.filter_map(fn(t) {
    case t {
      core.PieceFalling(position:, piece:, tween: _) -> {
        let piece_mat = piece_material(piece)
        let p_transform = piece_transform(None, position, time, Ok(t))

        Ok(scene.mesh(
          id: id(Piece(piece.id)),
          transform: p_transform,
          geometry: piece_geo,
          material: piece_mat,
          physics: None,
        ))
      }
      _ -> Error(Nil)
    }
  })
}
