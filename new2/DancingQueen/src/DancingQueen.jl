module DancingQueen

import TOML
using Dates
using StaticArrays, AprilTags, LibSerialPort, COBSReduced, ImageDraw, Observables
import ColorTypes: RGB, N0f8
using VideoIO

export main

const SV = SVector{2, Float64}
const SVI = SVector{2, Int}
const Color = RGB{N0f8}

const path2preferences = joinpath(@__DIR__, "..", "preferences.toml")
const path2data = joinpath(@__DIR__, "..", "..", "data")
const prefs = TOML.parsefile(path2preferences)
const baudrate = prefs["arena"]["baudrate"]
const nleds = prefs["arena"]["nleds"]
const tag_pixel_width = prefs["detection"]["tag_pixel_width"]
const widen_radius = prefs["detection"]["widen_radius"]
# const w = prefs["camera"]["width"]
# const h = prefs["camera"]["height"]

include("camera.jl")
include("detector.jl")
include("suns.jl")
include("tracker.jl")
include("leds.jl")
include("logs.jl")
include("display.jl")

struct Instance{N}
    logbook::LogBook
    suns::NTuple{N, Sun}
    cam::Camera
    detector::DetectoRect
    tracker::Track{N}
    leds::LEDs{N}
    frame::Frame{N}
    save::Bool
    status::Bool
    Instance(setup::Dict{String, any}) #here
end

function one_iter(save, cam, detector, tracker, leds, logbook, frame)
    snap(cam)
    beetle = detector(cam.img)
    tracker(beetle)
    update_suns!(tracker)
    leds(tracker.sun_θs)
    save && log!(logbook, beetle, leds)
    frame(cam.img, beetle, leds)
end

function start(setup::Dict{String, Any}, img)
    # initiate everything
    logbook = LogBook(setup)
    suns = Tuple((Sun(sun) for sun in setup["suns"]))
    cam = Camera("/dev/video2")
    detector = DetectoRect(size(cam)..., tag_pixel_width, widen_radius)
    tracker = Track(suns)
    leds = LEDs(baudrate, suns)
    frame = Frame(cam, suns)
    save = setup["label"] ≠ "Off"
    keep_going = Ref(true)
    # sample
    Threads.@spawn while keep_going[]
        one_iter(save, cam, detector, tracker, leds, logbook, frame)
    end
    img[] = frame.cimg
    return (; keep_going, cam, detector, leds, logbook)
end

function stop(instance)
    instance.keep_going[] = false
    sleep(0.1)
    # clean up
    close(instance.cam)
    close(instance.detector)
    close(instance.leds)
    close(instance.logbook)
end

function main(setup::Observable{Dict{String, Any}}, img::Ref{Matrix{Color}})
    instance = Ref{Any}(start(setup[], img))
    on(setup) do setup
        stop(instance[])
        instance[] = start(setup, img)
    end
end

end # module DancingQueen
