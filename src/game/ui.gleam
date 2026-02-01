import gleam/int
import game/bridge
import game/state.{type GameState, InGame, Loading, Menu, Paused}
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

type Model {
  Model(state: GameState, bridge: bridge.Bridge, current_score: Int)
}

pub type Msg {
  FromBridge(bridge.BridgeMsg)
}

fn init(bridge: bridge.Bridge, _flags) {
  #(Model(InGame, bridge, 0), ui.register_lustre(bridge, FromBridge))
}

fn update(model: Model, msg: Msg) {
  case msg {
    FromBridge(msg) -> handle_bridge_msg(model, msg)
    // GameStateChanged(state) -> #(Model(..model, state:), effect.none())
    // UserAction(_) -> {
    //   #(model, effect.none())
    // }
  }
}

fn handle_bridge_msg(model: Model, msg: bridge.BridgeMsg) {
  case msg {
    bridge.GameStateChanged(state) -> #(Model(..model, state:), effect.none())
    bridge.UserAction(_) -> #(model, effect.none())
    bridge.UpdateScore(score:) -> #(Model(..model, current_score: score), effect.none())
    _ -> #(model, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.id("game")], [
    html.div(
      [attribute.class("fixed top-0 left-0 w-full h-full pointer-events-none")],
      [
        case model.state {
          Loading -> view_loading(model)
          InGame -> view_in_game(model)
          Menu -> view_menu(model)
          Paused -> view_paused(model)
        },
      ],
    ),
  ])
}

fn view_paused(_model: Model) -> Element(Msg) {
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

fn view_menu(_model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "absolute inset-x-auto inset-y-1/2 text-3xl text-white text-center w-full h-full",
      ),
    ],
    [
      menu_title(),
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

fn view_in_game(model: Model) -> Element(Msg) {
  let lucy = case model.current_score {
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
    html.text(int.to_string(model.current_score))
  ])
}

fn view_loading(_model: Model) -> Element(Msg) {
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
