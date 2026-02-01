import gleam/int
import game/bridge
import game/state.{type GameState, InGame, Loading, Menu, Paused}
import game/controls.{type Action, MoveDown, MoveLeft, MoveRight, MoveUp, MenuToggle}
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import tiramisu/ui

pub fn start(bridge: bridge.Bridge) {
  let assert Ok(_) =
    lustre.application(init(bridge, _), update, view)
    |> lustre.start("#app", Nil)

  Nil
}

type StartMenuItem {
  NewGameItem
  ChangeControlsItem
}

type UIState {
  InGameHUD(score: Int)
  PausedMenu
  StartMenu(selection: StartMenuItem)
  LoadingScreen
}

type Model {
  Model(bridge: bridge.Bridge, state: UIState)
}

pub type Msg {
  FromBridge(bridge.BridgeMsg)
}

fn init(bridge: bridge.Bridge, _flags) {
  #(Model(bridge:, state: StartMenu(selection: NewGameItem)), ui.register_lustre(bridge, FromBridge))
}

fn update(model: Model, msg: Msg) {
  case msg {
    FromBridge(msg) -> handle_bridge_msg(model, msg)
  }
}

fn handle_bridge_msg(model: Model, msg: bridge.BridgeMsg) {
  case msg {
    bridge.GameStateChanged(state) -> handle_state_change(model, state)
    bridge.UserAction(action) -> handle_user_action(model, action)
    bridge.UpdateScore(score:) -> handle_update_score(model, score)
    _ -> #(model, effect.none())
  }
}

fn handle_state_change(model: Model, state: GameState) {
  case state, model.state {
    Menu, StartMenu(_) |
    Loading, LoadingScreen |
    InGame, InGameHUD(_) |
    Paused, PausedMenu -> #(model, effect.none())

    Loading, _ -> #(Model(..model, state: LoadingScreen), effect.none())
    Menu, _ -> #(Model(..model, state: StartMenu(NewGameItem)), effect.none())
    InGame, _ -> #(Model(..model, state: InGameHUD(0)), effect.none())
    Paused, _ -> #(Model(..model, state: PausedMenu), effect.none())
  }
}

fn handle_update_score(model: Model, score: Int) {
  case model.state {
    InGameHUD(_) -> #(Model(..model, state: InGameHUD(score) ), effect.none())
    _ -> #(model, effect.none())
  }
}

fn handle_user_action(model: Model, action: controls.Action) {
  case model.state {
    StartMenu(selection:) -> {
      case action {
        MoveUp | MoveLeft -> #(
          Model(..model, state: StartMenu(prev_start_menu_item(selection))),
          effect.none()
        )
        MoveDown | MoveRight -> #(
          Model(..model, state: StartMenu(next_start_menu_item(selection))),
          effect.none()
        )
        MenuToggle -> #(model, effect.none())
      }
    }
    _ -> #(model, effect.none())
  }
}

fn next_start_menu_item(item: StartMenuItem) {
  // TODO: update when we have more than two menu items
  prev_start_menu_item(item)
}

fn prev_start_menu_item(item: StartMenuItem) {
  case item {
    NewGameItem -> ChangeControlsItem
    ChangeControlsItem ->  NewGameItem
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.id("game")], [
    html.div(
      [attribute.class("fixed top-0 left-0 w-full h-full pointer-events-none")],
      [
        case model.state {
          InGameHUD(score:) -> view_in_game(score)
        PausedMenu -> view_paused()
        StartMenu(selection:) -> view_menu(selection)
        LoadingScreen -> view_loading()
        }
      ],
    ),
  ])
}

fn view_paused() -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "absolute inset-x-auto inset-y-1/2 text-8xl text-white text-center w-full h-full",
      ),
    ],
    [
      html.text("Paused"),
    ],
  )
}

fn view_menu(selection: StartMenuItem) -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "absolute inset-x-auto inset-y-1/2 text-3xl text-white text-center w-full h-full",
      ),
    ],
    [
      menu_title(),
      html.div([
        attribute.class("mx-auto py-3"),
        attribute.classes([#("text-shadow-lg text-shadow-pink-400", selection == NewGameItem)])
      ], [html.text("New Game")]),
      html.div([
        attribute.class("mx-auto"),
        attribute.classes([#("text-shadow-lg text-shadow-pink-400", selection == ChangeControlsItem)])
      ], [html.text("Change Controls")])
      // TODO: Add menu entries
    ],
  )
}

fn menu_title() -> Element(_) {
  html.img([
    attribute.src("game-title.png"),
    attribute.width(800),
    attribute.height(175),
    attribute.class("mx-auto"),
  ])
}

fn view_in_game(score: Int) -> Element(Msg) {
  let lucy = case score {
    s if s > 1000 -> "lucy-happy.png"
    s if s > 100 -> "lucy.png"
    _ -> "lucy-sleep.png"
  }
  html.div([
    attribute.class(
      "absolute text-2xl text-white top-2 left-2"
    )
  ],
  [
    html.img([
      attribute.width(40),
      attribute.height(40),
      attribute.src(lucy),
      attribute.class("inline mr-2"),
    ]),
    html.text(int.to_string(score))
  ])
}

fn view_loading() -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "absolute inset-x-auto inset-y-1/2 text-5xl text-white text-center h-full w-full",
      ),
    ],
    [
      html.text("Loading..."),
    ],
  )
}
