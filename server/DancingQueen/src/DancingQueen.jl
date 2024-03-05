module DancingQueen

using Dates, TOML
using StaticArrays, AprilTags, LibSerialPort, COBSReduced

export main

const SV = SVector{2, Float64}
const Color = SVector{3, UInt8}

const path2preferences = joinpath(@__DIR__, "..", "..", "..", "setup.toml")
const prefs = TOML.parsefile(path2preferences)
const baudrate = prefs["arena"]["baudrate"]
const nleds = prefs["arena"]["nleds"]
const camera_distance = prefs["detection"]["camera_distance"]
const tag_width = prefs["detection"]["tag_width"]
const widen_radius = prefs["detection"]["widen_radius"]

include("helpers.jl")
include("detector.jl")
include("camera.jl")
include("suns.jl")
include("leds.jl")
include("tracker.jl")

# const benchmark = Ref(now())
#
# function report_bm()
#     t = now()
#     Δ = t - benchmark[]
#     fps = 1000 ÷ max(1, Dates.value(Δ))
#     benchmark[] = t
#     if fps < 1000
#         println(fps)
#     end
# end

switch(current, ::Nothing) = current

function switch(camera::Camera, cm::CamMode)
    close(camera)
    Camera(cm)
end

function switch(tracker::Track, suns::NTuple)
    close(tracker)
    Track(suns)
end

function switch!(current, next)
    current[] = switch(current[], next[])
    next[] = nothing
end

function update!(setup::Dict, mode, suns, old_mode)
    new_mode = CamMode(setup)
    if old_mode ≠ new_mode
        mode[] = new_mode
    end
    suns[] = Tuple(Sun.(setup["suns"]))
end

function main()
    mode = Ref{Union{Nothing, CamMode}}(nothing)
    suns = Ref{Union{Nothing, NTuple}}(nothing)

    camera = Ref(Camera(cmoff))
    beetle = Ref{Union{Nothing, Beetle}}(nothing)
    tracker = Ref{Track}(Track(Tuple(Sun.([Dict("link_factor" => 0)]))))

    task = Threads.@spawn while true
        switch!(camera, mode)
        switch!(tracker, suns)
        if camera[].mode == cmoff
            sleep(1)
        else
            beetle[] = detect(camera[])
            tracker[](beetle[])
        end
    end

    return (
            setup -> update!(setup, mode, suns, camera[].mode), 
            () -> collect(camera[].img), 
            () -> (; datetime = now(), beetle = beetle[], leds = get_indices(tracker[].leds)),
            task
           )
end

end # module DancingQueen
