struct Beetle
    c::SV
    theta::Float64
end

get_min_radius(h, camera_fov) = h*2atand(tag_width/2camera_distance)/camera_fov/sqrt(2)

function set_detector!(detector, n=2)
    @assert Threads.nthreads() ≥ n
    detector.nThreads = n
    detector.quad_decimate =  1.0
    detector.quad_sigma = 0.0
    detector.refine_edges = 1
    detector.decode_sharpening = 0.25
    return detector
end

struct DetectoRect
    h::Int
    detector::AprilTagDetector
    rect::MVector{4, Int}
    min_radius::Float64
    function DetectoRect(cm::CamMode)
        detector = AprilTagDetector()
        set_detector!(detector)
        h = Int(cm)
        new(h, detector, MVector(1, 1, h, h), get_min_radius(h, get_camera_fov(cm)))
    end
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
        d.rect[1:2] .= max.(1, d.rect[1:2] .- widen_radius)
        d.rect[3:4] .= min.(d.h, d.rect[3:4] .+ widen_radius)
        return nothing
    else
        b = Beetle(only(tags), r1, c1)
        d.rect[1:2] .= max.(1, round.(Int, b.c .- d.min_radius::Float64))
        d.rect[3:4] .= min.(d.h, round.(Int, b.c .+ d.min_radius::Float64))
        return b
    end
end


