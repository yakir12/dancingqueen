module Track

import TOML
import ..Beetle, ..Sun, ..RGB, ..N0f8, ..LEDSun

export TrackedSun, update!, trackedsun_zero, set_suns, get_leds

const prefs = TOML.parsefile("preferences.toml")
const nleds = prefs["arena"]["nleds"]

mutable struct TrackedBeetle
    previouse_θ::Float64
    Δ::Float64
end

const tb = TrackedBeetle(0, 0)

function track!(tb::TrackedBeetle, beetle::Beetle)
    Δ = beetle.θ - tb.previouse_θ
    Δ += Δ > π ? -2π : Δ < -π ? 2π : 0
    tb.previouse_θ = beetle.θ
    tb.Δ = Δ
    return tb
end

mutable struct TrackedSun
    θ::Float64
    sun::Sun
end

trackedsun_zero() = TrackedSun(0, Sun(0, 1, zero(RGB{N0f8})))

const tsuns = [trackedsun_zero()]

function set_suns(new_tsuns::Vector{TrackedSun})
    empty!(tsuns)
    append!(tsuns, new_tsuns)
end

function rotate!(ts::TrackedSun, tb::TrackedBeetle)
    ts.θ += ts.sun.link_factor * tb.Δ
    return ts
end

α2index(α) = round(Int, nleds*α/2π + 0.5)

function LEDSun(ts::TrackedSun)
    i1 = α2index(mod(ts.θ - ts.sun.δ, 2π))
    i2 = α2index(mod(ts.θ + ts.sun.δ, 2π))
    LEDSun(i1, i2, ts.sun.color)
end

get_leds(::Nothing) = nothing

function get_leds(beetle::Beetle)
    track!(tb, beetle)
    for ts in tsuns
        rotate!(ts, tb)
    end
    return LEDSun.(tsuns)
end

end
