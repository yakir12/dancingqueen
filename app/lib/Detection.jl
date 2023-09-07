module Detection

using AprilTags, StaticArrays

export Beetle, DetectoRect, print_row

const SV = SVector{2, Float64}
const SVI = SVector{2, Int}

const w = Main.w
const h = Main.h
const sz = SVI(w, h)

tag_pixel_width = 45#37
const min_radius = tag_pixel_width/sqrt(2)
const widen_radius = 5

struct DetectoRect
    detector::AprilTagDetector
    rect::MVector{4, Int}
    DetectoRect() = new(AprilTagDetector(), MVector(1, 1, sz::SVI...))
end

function (d::DetectoRect)(buff)
    r1, c1, r2, c2 = d.rect
    img = buff[r1:r2, c1:c2]
    # detect
    tags = d.detector(img)
    if length(tags) ≠ 1 # not found
        d.rect[1:2] .= max.(1, d.rect[1:2] .- widen_radius::Int)
        d.rect[3:4] .= min.(sz::SVI, d.rect[3:4] .+ widen_radius::Int)
        return nothing
    else
        b = Beetle(only(tags), r1, c1)
        d.rect[1:2] .= max.(1, round.(Int, b.c .- min_radius::Float64))
        d.rect[3:4] .= min.(sz::SVI, round.(Int, b.c .+ min_radius::Float64))
        return b
    end
end

struct Beetle
    c::SV
    θ::Float64
end

function Beetle(tag, r1, c1)
    # center
    c0 = SV(reverse(tag.H[1:2,3]))
    # direction
    d = sum(p -> SV(reverse(p)) - c0, tag.p[1:2])
    θ = atan(d[2], d[1])
    # global center
    c = c0 + SV(r1, c1)
    Beetle(c, θ)
end

print_row(b) = string(b.c[1], ",", b.c[2], ",", b.θ)

end
