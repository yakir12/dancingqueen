module DancingQueen

using Dates
using StaticArrays, AprilTags, LibSerialPort, COBSReduced

export main

const SV = SVector{2, Float64}
const Color = SVector{3, UInt8}

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

get_state(::Nothing) = (; datetime = now(), beetle_c = missing, beetle_theta = missing)
get_state(beetle) = (; datetime = now(), beetle_c = beetle.c, beetle_theta = beetle.theta)

function main()
    mode = Ref{Union{Nothing, CamMode}}(nothing)
    suns = Ref{Union{Nothing, NTuple}}(nothing)

    camera = Ref(Camera(cmoff))
    beetle = Ref{Union{Nothing, Beetle}}(nothing)
    tracker = Ref(Track(Tuple(Sun.([Dict("link_factor" => 0)]))))

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
            () -> get_state(beetle[]),
            task
           )
end

end # module DancingQueen
