module DancingQueen

import TOML
using Dates
using StaticArrays, AprilTags, LibSerialPort, COBSReduced, Observables, ImageCore
import ColorTypes: N0f8, Gray

export main, get_image, get_state

const SV = SVector{2, Float64}
const SVI = SVector{2, Int}
const Color = RGB{N0f8}

const l = ReentrantLock()
const path2preferences = joinpath(@__DIR__, "..", "preferences.toml")
# const path2data = joinpath(@__DIR__, "..", "..", "data")
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
# include("logs.jl")
# include("display.jl")

const off_sun = Dict("camera" => 2464, "suns" => [Dict("link_factor" => 0)])

# const benchmark = Ref(now())
#
# function report_bm()
#     t = now()
#     Δ = t - benchmark[]
#     fps = 1000 ÷ max(1, Dates.value(Δ))
#     benchmark[] = t
#     println(fps)
# end

get_image(cam::Ref{Camera}) = collect(reshape(rawview(channelview(cam[].img)), :))

struct Instance{N}
    suns::NTuple{N, Sun}
    detector::DetectoRect
    beetle::Ref{Union{Nothing, Beetle}}
    tracker::Track{N}
    leds::LEDs{N}
    running::Ref{Bool}
    task::Task
    function Instance{N}(cam, suns::NTuple{N, Sun}) where N
        detector = DetectoRect(cam.h, camera_distance, tag_width, widen_radius)
        beetle = Ref{Union{Nothing, Beetle}}(nothing)
        tracker = Track(suns)
        leds = LEDs(baudrate, suns)
        running = Ref(true)
        task = Threads.@spawn while running[]
            one_iter(cam, detector, beetle, tracker, leds)
            # report_bm()
            yield()
        end
        new(suns, detector, beetle, tracker, leds, running, task)
    end
end
Instance(cam, suns::NTuple{N, Sun}) where {N} = Instance{N}(cam, suns)
Instance(cam, suns) = Instance(cam, Tuple(Sun.(suns)))

get_state(i::Ref{Instance}) = (i[].beetle, i[].leds, i[].detector.rect)

function one_iter(cam, detector, beetle, tracker, leds)
    beetle[] = detector(snap(cam))
    tracker(beetle[])
    update_suns!(tracker)
    leds(tracker.sun_θs)
end

function stop(i::Instance)
    i.running[] = false
    wait(i.task)
    close(i.detector)
    close(i.leds)
end

function main()
    setup = Observable(off_sun; ignore_equal_values = true)
    cam = Ref(Camera(setup[]["camera"]))
    instance = Ref(Instance(cam[], setup[]["suns"]))
    on(setup) do setup
        stop(instance[])
        cam_height = get(setup, "camera", 1080)
        if cam_height ≠ cam[].h
            close(cam[])
            cam[] = Camera(cam_height)
        end
        instance[] = Instance(cam[], setup["suns"])
    end
    return setup, cam, instance
end

end # module DancingQueen
