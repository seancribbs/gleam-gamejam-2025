import game/assets
import game/scene.{Background, id} as _
import gleam/option.{type Option, None}
import gleam_community/maths
import tiramisu/geometry
import tiramisu/material
import tiramisu/scene
import tiramisu/transform
import vec/vec3

pub fn background(textures: Option(assets.LoadedTextures)) -> scene.Node {
  let assert Ok(bg_geo) = geometry.plane(20.0, 20.0 /. 1.4989148128)
  let assert Ok(bg_mat) =
    material.basic(
      color: 0xffffff,
      transparent: True,
      opacity: 0.4,
      map: option.map(textures, fn(t) { t.starfield }),
    )
  scene.mesh(
    id: id(Background),
    transform: transform.at(vec3.Vec3(0.0, 0.0, 999.0))
      |> transform.rotate_y(maths.pi()),
    geometry: bg_geo,
    material: bg_mat,
    physics: None,
  )
}
