struct Beetle
    c::SV
    θ::Float64
end
Base.zero(::Type{Beetle}) = Beetle(zero(SV), 0)

struct DetectoRect
    detector::AprilTagDetector
    rect::MVector{4, Int}
    sz::SVI
    min_radius::Float64
    widen_radius::Int
    DetectoRect(w, h, tag_pixel_width, widen_radius) = new(AprilTagDetector(), MVector(1, 1, w, h), SVI(w, h), tag_pixel_width/sqrt(2), widen_radius)
end

Base.close(d::DetectoRect) = freeDetector!(d.detector)

function Beetle(tag, r1, c1)
    # center
    c0 = SV(reverse(tag.H[1:2,3]))
    # direction
    dx, dy = sum(p -> SV(reverse(p)) - c0, tag.p[1:2])
    # global center
    c = c0 + SV(r1, c1)
    Beetle(c, atan(dy, dx))
end

function (d::DetectoRect)(buff)
    r1, c1, r2, c2 = d.rect
    cropped = buff[r1:r2, c1:c2]
    # detect
    tags = d.detector(cropped)
    if length(tags) ≠ 1 # not found
        d.rect[1:2] .= max.(1, d.rect[1:2] .- d.widen_radius::Int)
        d.rect[3:4] .= min.(d.sz::SVI, d.rect[3:4] .+ d.widen_radius::Int)
        return nothing
    else
        b = Beetle(only(tags), r1, c1)
        d.rect[1:2] .= max.(1, round.(Int, b.c .- d.min_radius::Float64))
        d.rect[3:4] .= min.(d.sz::SVI, round.(Int, b.c .+ d.min_radius::Float64))
        return b
    end
end


