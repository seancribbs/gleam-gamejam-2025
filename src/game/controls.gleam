import game/core
import game/state
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import tiramisu/input

pub type Action {
  MoveUp
  MoveDown
  MoveLeft
  MoveRight
  MenuToggle
}

const all_actions: List(Action) = [
  MenuToggle,
  MoveUp,
  MoveDown,
  MoveLeft,
  MoveRight,
]

const instantaneous_actions: List(Action) = [
  MenuToggle,
  MoveUp,
  MoveDown,
  MoveLeft,
  MoveRight,
]

const continuous_actions: List(Action) = []

pub type UserInputBinding {
  Key(input.Key)
  Button(input.GamepadButton)
}

pub type UserBindings =
  dict.Dict(UserInputBinding, Action)

pub type UIBindings =
  dict.Dict(Action, List(UserInputBinding))

pub const default_ui_bindings = [
  #(MoveUp, [Key(input.KeyW), Button(input.DPadUp)]),
  #(MoveDown, [Key(input.KeyS), Button(input.DPadDown)]),
  #(MoveLeft, [Key(input.KeyA), Button(input.DPadLeft)]),
  #(MoveRight, [Key(input.KeyD), Button(input.DPadRight)]),
  #(MenuToggle, [Key(input.Escape), Button(input.Start)]),
]

// Forward  [ W ] [ DPadUp ]
//

pub fn default_bindings() -> input.InputBindings(Action) {
  default_ui_bindings
  |> dict.from_list()
  |> ui_bindings_to_user()
  |> user_bindings_to_input_bindings()
}

pub fn user_bindings_to_input_bindings(
  user: UserBindings,
) -> input.InputBindings(Action) {
  dict.fold(user, input.new_bindings(), fn(bindings, key, value) {
    case key {
      Button(button) -> input.bind_gamepad_button(bindings, button, value)
      Key(key) -> input.bind_key(bindings, key, value)
    }
  })
}

pub fn user_bindings_to_ui(user: UserBindings) -> UIBindings {
  let empty =
    all_actions
    |> list.map(fn(a) { #(a, []) })
    |> dict.from_list()

  dict.fold(user, empty, fn(ui, input, action) {
    dict.upsert(ui, action, fn(b) {
      case b {
        Some(bindings) -> [input, ..bindings]
        None -> [input]
      }
    })
  })
}

pub fn ui_bindings_to_user(ui: UIBindings) -> UserBindings {
  dict.fold(ui, dict.new(), fn(user, action, inputs) {
    list.fold(inputs, user, fn(user, input) { dict.insert(user, input, action) })
  })
}

pub fn handle_input(
  board: core.Board,
  state: state.GameState,
  bindings: input.InputBindings(Action),
  input: input.InputState,
) -> #(core.Board, state.GameState) {
  case state {
    state.Loading | state.Menu | state.Paused -> #(board, state)
    state.InGame -> {
      let actions = gameplay_actions(input, bindings)

      use #(board, state), action <- list.fold(actions, #(board, state))
      case action {
        MoveUp -> #(core.move_selected_out(board), state)
        MoveDown -> #(core.move_selected_in(board), state)
        MoveLeft -> #(core.user_rotate_left(board), state)
        MoveRight -> #(core.user_rotate_right(board), state)
        MenuToggle -> #(board, state)
        // TODO: Let the user toggle
      }
    }
  }
}

pub fn gameplay_actions(
  state: input.InputState,
  bindings: input.InputBindings(Action),
) -> List(Action) {
  let now =
    instantaneous_actions
    |> list.filter(fn(action) {
      input.is_action_just_pressed(state, bindings, action)
    })

  let ongoing =
    continuous_actions
    |> list.filter(fn(action) {
      input.is_action_pressed(state, bindings, action)
    })

  list.append(now, ongoing)
}

pub fn menu_actions(
  state: input.InputState,
  bindings: input.InputBindings(Action),
) -> List(Action) {
  all_actions
  |> list.filter(fn(action) {
    input.is_action_just_pressed(state, bindings, action)
  })
}
