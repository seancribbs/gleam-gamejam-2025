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
  let aspect_ratio = ctx.canvas_width /. ctx.canvas_height
  let half_x = case ctx.canvas_width <. ctx.canvas_height {
    True -> 10.0 /. aspect_ratio
    False -> 10.0
  }
  let half_y = case ctx.canvas_width <. ctx.canvas_height {
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
    transform: transform.at(vec3.Vec3(0.0, 0.0, 0.0)),
    look_at: Some(vec3.Vec3(0.0, 0.0, 1000.0)),
    viewport: None,
    postprocessing: None,
  )
}
