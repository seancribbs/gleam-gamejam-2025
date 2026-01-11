import game/scene.{RootCamera, id} as _
import gleam/option.{None, Some}
import tiramisu
import tiramisu/camera
import tiramisu/scene
import tiramisu/transform
import vec/vec3

pub fn root_camera(ctx: tiramisu.Context) -> scene.Node {
  // let assert Ok(camera) =
  //   camera.perspective(field_of_view: 75.0, near: 0.1, far: 1000.0)
  let canvas_width = ctx.canvas_size.x
  let canvas_height = ctx.canvas_size.y
  let aspect_ratio = canvas_width /. canvas_height
  let half_x = case canvas_width <. canvas_height {
    True -> 10.0 /. aspect_ratio
    False -> 10.0
  }
  let half_y = case canvas_width <. canvas_height {
    True -> 10.0
    False -> 10.0 /. aspect_ratio
  }
  let camera =
    camera.orthographic(
      left: 0.0 -. half_x,
      right: half_x,
      top: half_y,
      bottom: 0.0 -. half_y,
      near: 0.1,
      far: 1000.0,
    )

  scene.camera(
    id: id(RootCamera),
    camera: camera,
    active: True,
    transform: transform.look_at(
      from: transform.at(vec3.Vec3(0.0, 0.0, 0.0)),
      to: transform.at(vec3.Vec3(0.0, 0.0, 1000.0)),
      up: Some(vec3.Vec3(0.0, 1.0, 0.0)),
    ),
    viewport: None,
    postprocessing: None,
  )
}
