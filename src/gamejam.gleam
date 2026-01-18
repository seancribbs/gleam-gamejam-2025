import game/assets
import game/controls
import game/core
import game/scene as gamescene
import game/scene/background
import game/scene/board
import game/scene/camera
import game/scene/lights
import game/scene/overlay
import game/state.{type GameState, InGame, Loading, Menu, Paused}
import game/ui as gameui

import gleam/option.{type Option, None, Some}
import gleam/time/duration

import savoiardi
import tiramisu
import tiramisu/effect.{type Effect}
import tiramisu/input
import tiramisu/scene

pub type Model {
  Model(
    state: GameState,
    time: duration.Duration,
    board: core.Board,
    input: input.InputBindings(controls.Action),
    textures: Option(assets.LoadedTextures),
  )
}

pub type Msg {
  Tick
  AssetsLoaded(assets.LoadedTextures)
  AssetLoadingFailed
}

pub fn main() -> Nil {
  gameui.start()

  let app = tiramisu.application(init:, update:, view:)

  let assert Ok(_) = tiramisu.start(app, "#game", tiramisu.FullScreen, None)

  Nil
}

fn init(ctx: tiramisu.Context) -> #(Model, Effect(Msg), Option(_)) {
  savoiardi.set_scene_background_color(ctx.scene, 0)
  #(
    Model(
      state: Menu,
      time: duration.milliseconds(0),
      board: core.new_board(),
      input: controls.default_bindings(),
      textures: None,
    ),
    assets.load_all(on_success: AssetsLoaded, on_fail: AssetLoadingFailed),
    None,
  )
}

fn update(
  model: Model,
  msg: Msg,
  ctx: tiramisu.Context,
) -> #(Model, Effect(Msg), Option(_)) {
  case msg {
    // TODO: branch on game state
    Tick -> {
      case model.state {
        InGame -> {
          let new_time = duration.add(model.time, ctx.delta_time)
          // process board tick
          let #(board, state) =
            core.handle_tick(model.board, ctx.delta_time)
            |> controls.handle_input(model.state, model.input, ctx.input)
          // handle user input (queueing transitions)

          // dispatch UI updates
          #(
            Model(..model, time: new_time, board:, state:),
            effect.batch([
              // ui.dispatch_to_lustre(gameui.CurrentTime(new_time)),
              effect.dispatch(Tick),
            ]),
            None,
          )
        }
        Loading | Menu | Paused -> {
          let #(board, state) =
            controls.handle_input(
              model.board,
              model.state,
              model.input,
              ctx.input,
            )
          #(Model(..model, board:, state:), effect.dispatch(Tick), None)
        }
      }
    }
    AssetsLoaded(textures) -> {
      #(
        Model(..model, textures: Some(textures), state: InGame),
        effect.dispatch(Tick),
        None,
      )
    }
    AssetLoadingFailed -> {
      // TODO: Display an error message about being unable to load assets
      #(model, effect.none(), None)
    }
  }
}

fn view(model: Model, ctx: tiramisu.Context) -> scene.Node {
  gamescene.root_scene([
    camera.root_camera(ctx),
    lights.lights(model.time),
    background.background(model.textures),
    board.board(model.state, model.board, model.time),
    overlay.overlay(model.state),
  ])
}
