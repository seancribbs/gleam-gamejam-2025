/// 3D Game Example - Perspective Camera with Lighting
import gleam/option.{type Option, None}
import tiramisu
import tiramisu/background

// import tiramisu/camera
import tiramisu/effect.{type Effect}

// import tiramisu/geometry
// import tiramisu/light
// import tiramisu/material
import tiramisu/scene
import tiramisu/transform

// import vec/vec3

pub type Model {
  Model(time: Float)
}

pub type Msg {
  Tick
}

pub fn main() -> Nil {
  tiramisu.run(
    dimensions: None,
    background: background.Color(0x1a1a2e),
    init:,
    update:,
    view:,
  )
}

fn init(_ctx: tiramisu.Context(String)) -> #(Model, Effect(Msg), Option(_)) {
  #(Model(time: 0.0), effect.tick(Tick), None)
}

fn update(
  model: Model,
  msg: Msg,
  ctx: tiramisu.Context(String),
) -> #(Model, Effect(Msg), Option(_)) {
  case msg {
    Tick -> {
      let new_time = model.time +. ctx.delta_time
      #(Model(time: new_time), effect.tick(Tick), None)
    }
  }
}

fn view(_model: Model, _ctx: tiramisu.Context(String)) -> scene.Node(String) {
  scene.empty(id: "Scene", transform: transform.identity, children: [])
}
