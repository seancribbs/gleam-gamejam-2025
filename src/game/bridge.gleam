import game/controls
import game/state.{type GameState}
import tiramisu/ui

pub type Bridge =
  ui.Bridge(BridgeMsg)

pub type BridgeMsg {
  // Game -> UI: state transitions
  GameStateChanged(GameState)
  UserAction(controls.Action)
  // Game -> UI: data updates
  UpdateScore(score: Int)
  // UI -> Game: user actions
  ChangeControlBinding(
    action: controls.Action,
    bindings: List(controls.UserInputBinding),
  )
  NewGame
}
