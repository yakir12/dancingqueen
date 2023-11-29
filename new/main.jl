using Observables
import TOML
import ColorTypes: RGB, N0f8

const prefs = TOML.parsefile("preferences.toml")
const nleds = prefs["arena"]["nleds"]

const Color = RGB{N0f8}

struct Sun
    link_factor::Float64
    width::Int
    color::Color
    azimuth::Float64
end
Sun() = Sun(0, 1, zero(Color), 0)

# angular_radius(s::Sun) = (s.width - 1)*π/nleds

struct Setup
    label::String
    key::Char
    suns::Vector{Sun}
end
Setup() = Setup("Off", 'a', [Sun()])

setups = Observable([off])

chosen = map(_ -> 1, setups)

suns = map(i >setups[][i].suns, chosen)


