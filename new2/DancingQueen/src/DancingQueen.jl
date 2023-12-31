module DancingQueen

import TOML
using Dates
using StaticArrays, AprilTags, LibSerialPort, COBSReduced, ImageDraw, Observables, ImageCore, ImageTransformations
import ColorTypes: RGB, N0f8, Gray

export main

const SV = SVector{2, Float64}
const SVI = SVector{2, Int}
const Color = RGB{N0f8}

const l = ReentrantLock()
const path2preferences = joinpath(@__DIR__, "..", "preferences.toml")
const path2data = joinpath(@__DIR__, "..", "..", "data")
const prefs = TOML.parsefile(path2preferences)
const baudrate = prefs["arena"]["baudrate"]
const nleds = prefs["arena"]["nleds"]
const camera_distance = prefs["detection"]["camera_distance"]
const tag_width = prefs["detection"]["tag_width"]
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

const off_sun = Dict("label" => "Off", "camera" => 2464, "suns" => [Dict("link_factor" => 0)])

# const benchmark = Ref(now())
#
# function report_bm()
#     t = now()
#     Δ = t - benchmark[]
#     fps = 1000 ÷ max(1, Dates.value(Δ))
#     benchmark[] = t
#     println(fps)
# end

int2enum(::Missing) = best

struct Instance{N}
    logbook::LogBook
    suns::NTuple{N, Sun}
    cam::Camera
    detector::DetectoRect
    tracker::Track{N}
    leds::LEDs{N}
    frame::Frame{N}
    running::Ref{Bool}
    task::Task
    function Instance{N}(suns::NTuple{N, Sun}, setup::Dict{String, Any}, img) where N
        logbook = LogBook(setup)
        cam = Camera(get(setup, "camera", 1080))
        detector = DetectoRect(cam.h, camera_distance, tag_width, widen_radius)
        tracker = Track(suns)
        leds = LEDs(baudrate, suns)
        frame = Frame(cam.h, suns)
        running = Ref(true)
        img[] = frame.smaller
        task = Threads.@spawn while running[]
            one_iter(cam, detector, tracker, leds, logbook, frame)
            # report_bm()
            yield()
        end
        new(logbook, suns, cam, detector, tracker, leds, frame, running, task)
    end
end
Instance(suns::NTuple{N, Sun}, setup::Dict{String, Any}, img) where {N} = Instance{N}(suns, setup, img)
function Instance(setup::Dict{String, Any}, img)
    suns = Tuple((Sun(sun) for sun in setup["suns"]))
    Instance(suns, setup, img)
end

function one_iter(cam, detector, tracker, leds, logbook, frame)
    snap(cam)
    beetle = detector(cam.img)
    tracker(beetle)
    update_suns!(tracker)
    leds(tracker.sun_θs)
    log_print(logbook, beetle, leds)
    frame(cam.img, beetle, leds, detector.rect)
end

function stop(i::Instance)
    i.running[] = false
    wait(i.task)
    close(i.cam)
    close(i.detector)
    close(i.leds)
end

function main()
    setup = async_latest(Observable(off_sun), 1) # do I need this?
    img = Ref(zeros(Color, 10, 10))
    instance = Ref{Instance}(Instance(setup[], img))
    on(setup) do setup
        @lock l begin
            stop(instance[])
            instance[] = Instance(setup, img)
        end
    end
    return setup, img
end

end # module DancingQueen
