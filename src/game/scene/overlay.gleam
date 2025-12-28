// import game/core
import game/scene.{Overlay, OverlayMask, id} as _
import game/state.{Menu, Paused}
import gleam/option.{None}
import gleam_community/colour
import tiramisu/geometry
import tiramisu/material
import tiramisu/scene
import tiramisu/transform
import vec/vec3

pub fn overlay(state: state.GameState) -> scene.Node {
  let overlay = case state {
    Paused | Menu -> [
      scene.mesh(
        id: id(OverlayMask),
        transform: transform.at(vec3.Vec3(0.0, 0.0, 0.11)),
        geometry: {
          let assert Ok(geo) = geometry.plane(30.0, 30.0)
          geo
        },
        material: {
          let assert Ok(m) =
            material.basic(
              color: colour.dark_gray |> colour.to_rgb_hex,
              map: None,
              transparent: True,
              opacity: 0.7,
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
