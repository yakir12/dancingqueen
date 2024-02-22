module DancingQueen

import TOML
using VideoIO, StaticArrays
import ColorTypes: RGB, N0f8

const prefs = TOML.parsefile("preferences.toml")
const nleds = prefs["arena"]["nleds"]

const SV = SVector{2, Float64}

struct Beetle
    c::SV
    θ::Float64
end

struct Sun
    link_factor::Float64
    width::Int
    color::RGB{N0f8}
    δ::Float64 # angular radius

    Sun(link_factor, width, color) = new(link_factor, width, color, (width - 1)*π/nleds)
end

include("Detection.jl")
using .Detection

include("LEDs.jl")
using .LEDs

include("Track.jl")
using .Track

# export TrackedSun
include("LogBooks.jl")
using .LogBooks

export LEDStrip, set_suns, set_recording, get_recordings, get_state, SV, trackedsun_zero

# VideoIO.DEFAULT_CAMERA_DEVICE[] = "/dev/video2"

const cam = opencamera()
const img = read(cam)
const beetle = Ref{Union{Nothing, Beetle}}(nothing)

task = Threads.@spawn while isopen(cam)
    read!(cam, img)
    beetle[] = detection(img)
    leds = get_leds(beetle[])
    # Threads.@spawn 
    log_record(beetle[], leds)
    sleep(0.001)
    yield()
end

get_state() = (; img, beetle = beetle[], leds = get_leds(beetle[]))

end

