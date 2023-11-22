module DancingQueen

import TOML
using VideoIO, StaticArrays
import ColorTypes: RGB, N0f8

const prefs = TOML.parsefile("preferences.toml")
const nleds = prefs["leds"]["n"]

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

include("Track.jl")
using .Track

# export TrackedSun
include("LogBooks.jl")
using .LogBooks

include("LEDs.jl")
using .LEDs

export LEDStrip, set_suns, set_recording, get_recordings, get_state, SV, trackedsun_zero

# VideoIO.DEFAULT_CAMERA_DEVICE[] = "/dev/video2"

const cam = opencamera()
const img = read(cam)
const beetle = Ref{Union{Nothing, Beetle}}(nothing)
const tsuns = [trackedsun_zero()]

task = Threads.@spawn while isopen(cam)
    read!(cam, img)
    beetle[] = detection(img)
    update!(tsuns, beetle[])
    # Threads.@spawn 
    log_record(beetle[], tsuns)
    sleep(0.001)
    yield()
end

function set_suns(new_tsuns::Vector{TrackedSun})
    empty!(tsuns)
    append!(tsuns, new_tsuns)
end

get_state() = (; img, beetle = beetle[], tsuns)

end

