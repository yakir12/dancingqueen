module DancingQueen

import TOML
using Dates
using StaticArrays, AprilTags, LibSerialPort, COBSReduced, Observables

export main

const SV = SVector{2, Float64}
const Color = SVector{3, UInt8}

const path2preferences = joinpath(@__DIR__, "..", "preferences.toml")
const prefs = TOML.parsefile(path2preferences)
const baudrate = prefs["arena"]["baudrate"]
const nleds = prefs["arena"]["nleds"]
const camera_distance = prefs["detection"]["camera_distance"]
const tag_width = prefs["detection"]["tag_width"]
const widen_radius = prefs["detection"]["widen_radius"]

include("camera.jl")
include("detector.jl")
include("suns.jl")
include("tracker.jl")
include("leds.jl")

const off_sun = Dict("camera" => 0, "suns" => [Dict("link_factor" => 0)])


mutable struct Controller
    paused::Bool
    condition::Condition
end
check(controller::Controller) = controller.paused && wait(controller.condition)
pause!(controller::Controller) = (controller.paused = true)
function resume!(controller::Controller) 
    controller.paused = false
    notify(controller.condition)
end





# const benchmark = Ref(now())
#
# function report_bm()
#     t = now()
#     Δ = t - benchmark[]
#     fps = 1000 ÷ max(1, Dates.value(Δ))
#     benchmark[] = t
#     println(fps)
# end

# get_image(cam::Ref{Camera}) = collect(reshape(rawview(channelview(cam[].img)), :))

struct Instance{N, H}
    suns::NTuple{N, Sun}
    detector::DetectoRect{H}
    beetle::Ref{Union{Nothing, Beetle}}
    tracker::Track{N}
    leds::LEDs{N}
    running::Ref{Bool}
    task::Task
    function Instance(cam::Camera{H}, suns::NTuple{N, Sun}) where {N, H}
        detector = DetectoRect(cam, camera_distance, tag_width, widen_radius)
        beetle = Ref{Union{Nothing, Beetle}}(nothing)
        tracker = Track(suns)
        leds = LEDs(baudrate, suns)
        running = Ref(true)
        task = Threads.@spawn while running[]
            one_iter(cam, detector, beetle, tracker, leds)
            # report_bm()
            yield()
        end
        new{N, H}(suns, detector, beetle, tracker, leds, running, task)
    end
end
# Instance(cam::Camera{H}, suns::NTuple{N, Sun}) where {N, H} = Instance{N, H}(cam, suns)
Instance(cam, suns) = Instance(cam, Tuple(Sun.(suns)))

function one_iter(cam, detector, beetle, tracker, leds)
    beetle[] = detector(snap(cam))
    tracker(beetle[])
    update_suns!(tracker)
    leds(tracker.sun_θs)
end

function stop(i::Instance)
    if i.running[]
        i.running[] = false
        wait(i.task)
        close(i.detector)
        close(i.leds)
    end
end

function main()
    setup = Observable(off_sun; ignore_equal_values = true)
    cam = Ref(Camera(setup[]))
    instance = Ref{Instance}(Instance(cam[], setup[]["suns"]))
    on(setup) do setup
        pause!(resume)
        switch!(cam, setup)
        instance[] = Instance(cam[], setup["suns"])
        play!(resume)
    end
    get_bytes() = vec(cam[].img)
    get_state() = (datetime = now(), rect = instance[].detector.rect, beetle = instance[].beetle[], leds = instance[].leds.msg)
    return setup, get_bytes, get_state
end

function main()
    setup = Observable(off_sun)
    instance = Instance(setup[])
    on(setup -> update!(instance, setup), setup)
    return setup, () -> get_bytes(instance), () -> get_state(instance)
end

end # module DancingQueen
