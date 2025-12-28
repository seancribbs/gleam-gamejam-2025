import game/state.{type GameState, InGame, Loading, Menu, Paused}
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html

pub fn start() {
  let assert Ok(_) =
    lustre.application(init, update, view)
    |> lustre.start("#app", Nil)

  Nil
}

type Model {
  Model(state: GameState)
}

pub type Msg {
  LoadingFinished
}

fn init(_flags) {
  #(Model(InGame), effect.none())
}

fn update(_model: Model, msg: Msg) {
  case msg {
    LoadingFinished -> #(Model(state: Menu), effect.none())
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
        "absolute inset-x-auto inset-y-1/2 text-3xl text-white text-center w-full h-full",
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

fn view_in_game(_model: Model) -> Element(Msg) {
  element.none()
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
