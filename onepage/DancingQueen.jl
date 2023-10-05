module DancingQueen

using VideoIO, StaticArrays, Colors
import Colors.N0f8

const SV = SVector{2, Float64}
const w, h = (720, 1280)
const nleds = 100

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
include("Track.jl")
include("LogBooks.jl")
include("LEDs.jl")

using .Detection, .Track, .LogBooks, .LEDs

# export Sun # maybe remove?
export LEDStrip, TrackedSun
export set_suns, set_recording, get_recordings, get_state, w, h, nleds, SV, trackedsun_zero

const cam = opencamera()
const img = read(cam)
const beetle = Ref{Union{Nothing, Beetle}}(nothing)
const tsuns = [trackedsun_zero()]

task = Threads.@spawn while isopen(cam)
    read!(cam, img)
    beetle[] = detection(img)
    update!(tsuns, beetle[])
    Threads.@spawn log_record(beetle[], tsuns...)
end

function set_suns(new_tsuns::Vector{TrackedSun})
    empty!(tsuns)
    append!(tsuns, new_tsuns)
end

get_state() = (; img, beetle = beetle[], tsuns)

end

