import game/texture_ext
import gleam/javascript/promise
import gleam/list
import gleam/result
import savoiardi
import tiramisu/effect
import tiramisu/texture

pub const lucy = "lucy.png"

pub const lucy_happy = "lucy-happy.png"

pub const lucy_sleep = "lucy-sleep.png"

pub const starfield = "starfield.jpg"

pub const all_assets = [
  lucy,
  lucy_happy,
  lucy_sleep,
  starfield,
]

pub type LoadedTextures {
  LoadedTextures(
    lucy: texture.Texture,
    lucy_happy: texture.Texture,
    lucy_sleep: texture.Texture,
    starfield: texture.Texture,
  )
}

pub fn load_all(
  on_success on_success: fn(LoadedTextures) -> a,
  on_fail on_fail: a,
) -> effect.Effect(a) {
  all_assets
  |> list.map(savoiardi.load_texture)
  |> promise.await_list
  |> promise.map(fn(textures) {
    case result.all(textures) {
      Ok([lucy, lucy_happy, lucy_sleep, starfield, ..]) ->
        on_success(LoadedTextures(
          lucy:,
          lucy_happy:,
          lucy_sleep:,
          starfield: texture_ext.set_srgb_color_space(starfield),
        ))
      _ -> on_fail
    }
  })
  |> effect.from_promise()
}
