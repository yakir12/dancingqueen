module DancingQueen

using Dates
using Observables, StaticArrays, AprilTags, JSONSchema, JSON3, VideoIO, Preferences
import TOML, Tar
import ColorTypes: RGB, N0f8
# Observables, StaticArrays, AprilTags, JSONSchema, JSON3, VideoIO, TOML, Tar, ColorTypes, Dates

export start

const path2preferences = joinpath(@__DIR__, "..", "preferences.toml")
const path2schema = joinpath(@__DIR__, "..", "schema.json")
const path2data = joinpath(@__DIR__, "..", "..", "data")
const prefs = TOML.parsefile(path2preferences)
const nleds = prefs["arena"]["nleds"]
const w = prefs["camera"]["width"]
const h = prefs["camera"]["height"]

const Color = RGB{N0f8}
const SV = SVector{2, Float64}

struct Beetle
    c::SV
    θ::Float64
end
Base.zero(::Type{Beetle}) = Beetle(zero(SV), 0)

include("detection.jl")

const detector = Ref{DetectoRect}()

function __init__()
    detector[] = DetectoRect()
end

mutable struct Sun
    link_factor::Float64
    width::Int
    color::Color
    θ::Float64
    r::Int
    Sun(link_factor, width, color, θ) = new(link_factor, width, color, θ, (width - 1)/2)
end
Base.zero(::Type{Sun}) = Sun(0, 1, zero(Color), 0)

struct Setup
    label::String
    key::Char
    suns::Vector{Sun}
end
Base.zero(::Type{Setup}) = Setup("Off", 'a', [zero(Sun)])

include("tracking.jl")
include("leds.jl")
include("logs.jl")

function connect()
    setups = Observable([zero(Setup)])
    chosen = map(_ -> 1, setups)
    setup = map(i -> setups[][i], chosen)
    logbook = Ref(LogBook())
    on(setup) do setup
        close_log!(logbook[])
        if setup.label ≠ "Off"
            open_log!(logbook[], setup)
        end
    end
    suns = map(su -> su.suns, setup)
    img = Observable(PermutedDimsArray(rand(Color, h, w), (2,1)))
    beetle = Observable{Union{Nothing, Beetle}}()
    map!(img -> detector[](img), beetle, img)
    on(beetle) do beetle
        if !isnothing(beetle)
            track(beetle)
            rotate!.(suns[])
            notify(suns)
        end
    end
    leds = map(suns) do suns
        LEDSun.(suns)
    end
    on(leds) do leds
        log!(logbook[], beetle[], leds)
    end

    return (setups, chosen, img, beetle, leds)
end

function start()
    aa = @load_preference("a", 33)
    @show aa
    setups, chosen, img, beetle, leds = connect()
    cam = opencamera()
    task = Threads.@spawn while isopen(cam)
        read!(cam, img[])
        notify(img)
        sleep(0.001)
        yield()
    end
    return (setups, chosen, img, beetle, leds)
end

end # module DancingQueen
