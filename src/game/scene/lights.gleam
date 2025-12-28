import game/scene.{Light, Lights, id} as _
import gleam/time/duration
import gleam_community/maths
import tiramisu/light
import tiramisu/scene
import tiramisu/transform
import vec/vec3

const rotation_period_seconds: Float = 5000.0

pub fn lights(time: duration.Duration) -> scene.Node {
  let two_pi = maths.pi() *. 2.0
  let period = duration.to_seconds(time) /. rotation_period_seconds *. two_pi
  let x = maths.sin(period) *. 5.0
  let y = maths.cos(period) *. 5.0
  let position = vec3.Vec3(x, y, 90.0)
  scene.empty(id: id(Lights), transform: transform.identity, children: [
    ambient(0),
    directional(1),
    point(2, vec3.Vec3(-1.0, 2.0, 90.0)),
    point(3, position),
  ])
}

fn ambient(idx: Int) -> scene.Node {
  let assert Ok(ambient) = light.ambient(intensity: 3.0, color: 0xffffff)
  scene.light(id: id(Light(idx)), light: ambient, transform: transform.identity)
}

fn directional(idx: Int) -> scene.Node {
  let assert Ok(directional) = light.directional(1.0, color: 0xffffff)
  scene.light(
    id: id(Light(idx)),
    light: directional,
    transform: transform.at(vec3.Vec3(1.0, 1.0, 0.0)),
  )
}

fn point(idx: Int, position: vec3.Vec3(Float)) -> scene.Node {
  let assert Ok(point) =
    light.point(intensity: 2.0, color: 0xffffff, distance: 1000.0)

  scene.light(
    id: id(Light(idx)),
    light: point,
    transform: transform.at(position),
  )
}
