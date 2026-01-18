// import game/core
import game/scene.{Overlay, OverlayMask, id} as _
import game/state.{Menu, Paused}
import gleam/option.{None}
import gleam_community/colour
import gleam_community/maths
import tiramisu/geometry
import tiramisu/material
import tiramisu/scene
import tiramisu/transform
import vec/vec2
import vec/vec3

pub fn overlay(state: state.GameState) -> scene.Node {
  let overlay = case state {
    Paused | Menu -> [
      scene.mesh(
        id: id(OverlayMask),
        transform: transform.at(vec3.Vec3(0.0, 0.0, 0.11))
          |> transform.rotate_y(maths.pi()),
        geometry: {
          let assert Ok(geo) = geometry.plane(vec2.Vec2(30.0, 30.0))
          geo
        },
        material: {
          let assert Ok(m) =
            material.basic(
              color: colour.dark_charcoal |> colour.to_rgb_hex,
              map: None,
              transparent: True,
              opacity: 0.8,
              side: material.FrontSide,
              alpha_test: 0.0,
              depth_write: False,
            )
          m
        },
        physics: None,
      ),
    ]
    _ -> []
  }
  scene.empty(id: id(Overlay), transform: transform.identity, children: overlay)
}
