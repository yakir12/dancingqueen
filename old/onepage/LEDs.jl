module LEDs

import ColorTypes: RGB, N0f8
import TOML

export LEDSun

const prefs = TOML.parsefile("preferences.toml")
const nleds = prefs["arena"]["nleds"]

struct LEDSun
    i1::Int
    i2::Int
    color::RGB{N0f8}
end

function Base.iterate(ls::LEDSun, state=ls.i1)
    if ls.i2 < ls.i1
        state > nleds + ls.i2 - 1 ? nothing : (1 + rem(state - 1, nleds - 1), state + 1)
    else
        state > ls.i2 ? nothing : (state, state + 1)
    end
end

ledstrip_zero() = LEDSun(1, 1, zero(RGB{N0f8}))

end
