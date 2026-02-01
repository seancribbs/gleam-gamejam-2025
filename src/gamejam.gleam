import game/assets
import game/bridge
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
import gleam/dict
import gleam/list
import tiramisu/ui

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
    bridge: bridge.Bridge,
    time: duration.Duration,
    board: core.Board,
    bindings: controls.UserBindings,
    input: input.InputBindings(controls.Action),
    textures: Option(assets.LoadedTextures),
  )
}

pub type Msg {
  Tick
  AssetsLoaded(assets.LoadedTextures)
  AssetLoadingFailed
  FromBridge(bridge.BridgeMsg)
}

pub fn main() -> Nil {
  let bridge = ui.new_bridge()
  gameui.start(bridge)

  let app = tiramisu.application(init: init(bridge, _), update:, view:)

  let assert Ok(_) = tiramisu.start(app, "#game", tiramisu.FullScreen, None)

  Nil
}

fn init(
  bridge: bridge.Bridge,
  ctx: tiramisu.Context,
) -> #(Model, Effect(Msg), Option(_)) {
  savoiardi.set_scene_background_color(ctx.scene, 0)
  let bindings = controls.default_bindings()
  #(
    Model(
      state: Menu,
      bridge:,
      time: duration.milliseconds(0),
      board: core.new_board(),
      bindings:,
      input: controls.user_bindings_to_input_bindings(bindings),
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
    FromBridge(bridge_msg) -> handle_bridge_msg(model, bridge_msg)
    Tick -> handle_tick(model, ctx)
    AssetsLoaded(textures) -> {
      #(
        Model(..model, textures: Some(textures), state: Menu),
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

fn handle_bridge_msg(
  model: Model,
  msg: bridge.BridgeMsg,
) -> #(Model, Effect(Msg), Option(_)) {
  case msg {
    bridge.ChangeControlBinding(action:, bindings:) -> {
      let bindings = {
        use acc, b <- list.fold(bindings, model.bindings)
        dict.insert(acc, b, action)
      }
      let input = controls.user_bindings_to_input_bindings(bindings)
      #(Model(..model, bindings:, input:), effect.none(), None)
    }
    bridge.NewGame -> #(
      Model(..model, board: core.new_board()),
      effect.none(),
      None,
    )
    // bridge.GameStateChanged(_) -> todo
    // bridge.UserAction(_) -> todo
    // bridge.UpdateScore(score:) -> todo
    _ -> #(model, effect.none(), None)
  }
}

fn handle_tick(
  model: Model,
  ctx: tiramisu.Context,
) -> #(Model, Effect(Msg), Option(a)) {
  case model.state {
    InGame -> {
      let new_time = duration.add(model.time, ctx.delta_time)
      // process board tick
      // handle user input (queueing transitions)
      let #(board, state, forwarded_actions) =
        core.handle_tick(model.board, ctx.delta_time)
        |> controls.handle_input(model.state, model.input, ctx.input)

      // dispatch UI updates
      let ui_effects =
        forwarded_actions
        |> list.map(bridge.UserAction)
        |> list.map(ui.send_to_ui(model.bridge, _))

      #(
        Model(..model, time: new_time, board:, state:),
        effect.batch([
          effect.dispatch(Tick),
          ui.send_to_ui(model.bridge, bridge.GameStateChanged(state)),
          ui.send_to_ui(model.bridge, bridge.UpdateScore(core.current_score(board.state))),
          ..ui_effects
        ]),
        None,
      )
    }
    Loading | Menu | Paused -> {
      let #(board, state, forwarded_actions) =
        controls.handle_input(model.board, model.state, model.input, ctx.input)
      let ui_effects =
        forwarded_actions
        |> list.map(bridge.UserAction)
        |> list.map(ui.send_to_ui(model.bridge, _))

      #(
        Model(..model, board:, state:),
        effect.batch([
          effect.dispatch(Tick),
          ui.send_to_ui(model.bridge, bridge.GameStateChanged(state)),
          ..ui_effects
        ]),
        None,
      )
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
