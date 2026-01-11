import tiramisu/texture.{type Texture}

@external(javascript, "../gamejam.ffi.mjs", "setSRGBColorSpace")
pub fn set_srgb_color_space(t: Texture) -> Texture
