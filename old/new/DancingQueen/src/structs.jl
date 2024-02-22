struct Beetle
    c::SV
    θ::Float64
end
Base.zero(::Type{Beetle}) = Beetle(zero(SV), 0)

struct DetectoRect
    detector::AprilTagDetector
    rect::MVector{4, Int}
    DetectoRect() = new(AprilTagDetector(), MVector(1, 1, sz::SVI...))
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
    suns::Vector{Sun}
end
Base.zero(::Type{Setup}) = Setup("Off", [zero(Sun)])

