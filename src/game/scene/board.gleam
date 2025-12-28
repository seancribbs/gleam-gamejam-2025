// import game/core
import game/core
import game/piece
import game/scene.{BoardGroup, BoardRing, Piece, RingPieces, id} as _
import game/state.{type GameState, InGame, Paused}
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
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
          rings(),
          pieces(board, time),
        ])
      _ -> []
    },
  )
}

fn pieces(board: core.Board, time: duration.Duration) -> List(scene.Node) {
  let assert Ok(piece_geo) = geometry.icosahedron(radius: 0.25, detail: 0)
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
          let assert Ok(piece_mat) =
            material.new()
            |> material.with_color(piece.piece_color(p.kind))
            |> material.with_metalness(0.75)
            |> material.with_roughness(0.5)
            |> material.build()

          let p_transform = piece_transform(ring_name, i, time)

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

fn piece_transform(
  ring_name: core.RingName,
  position: Int,
  time: duration.Duration,
) -> transform.Transform {
  let distance = case ring_name {
    core.Inner -> 1.5
    core.Middle -> 2.25
    core.Outer -> 3.0
  }
  let time = duration.to_seconds(time)
  let angle = { maths.pi() /. 4.0 } *. int.to_float(position)
  let x = distance *. maths.cos(angle)
  let y = distance *. maths.sin(angle)
  transform.at(vec3.Vec3(x, y, 97.0))
  |> transform.rotate_y(time /. 1.0)
  |> transform.rotate_z(time /. 2.0)
  |> transform.rotate_x(time /. 5.0)
}

fn rings() -> List(scene.Node) {
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

  let transform = transform.at(vec3.Vec3(0.0, 0.0, 100.0))
  [
    scene.mesh(
      id: id(BoardRing(core.Inner)),
      transform:,
      geometry: inner_geo,
      material: ring_mat,
      physics: None,
    ),
    scene.mesh(
      id: id(BoardRing(core.Middle)),
      transform:,
      geometry: middle_geo,
      material: ring_mat,
      physics: None,
    ),
    scene.mesh(
      id: id(BoardRing(core.Outer)),
      transform:,
      geometry: outer_geo,
      material: ring_mat,
      physics: None,
    ),
  ]
}
