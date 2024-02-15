struct Beetle
    c::SV
    theta::Float64
end

get_camera_fov(h::Int) = 
    h == 480 ? 480/1232*48.8 :
    h == 1232 ? 48.8 :
    h == 1080 ? 1080/2464*48.8 :
    h == 2464 ? 48.8 :
    throw(ArgumentError("Wrong `h = $h`. Should be one of $(Int.(instances(DancingQueen.CamMode)))"))

get_min_radius(h, camera_distance, tag_width, camera_fov) = h*2atand(tag_width/2camera_distance)/camera_fov/sqrt(2)

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
    widen_radius::Int
    function DetectoRect(h)
        widen_radius = 15 # a value I think works....
        tag_width = 2 # cm
        camera_distance = 62 # cm, YOU HAVE TO CHANGE THIS TO REALITY!!!
        detector = AprilTagDetector()
        set_detector!(detector)
        new(h, detector, MVector(1, 1, h, h), get_min_radius(h, camera_distance, tag_width, get_camera_fov(h)), widen_radius)
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
        d.rect[1:2] .= max.(1, d.rect[1:2] .- d.widen_radius::Int)
        d.rect[3:4] .= min.(d.h, d.rect[3:4] .+ d.widen_radius::Int)
        return nothing
    else
        b = Beetle(only(tags), r1, c1)
        d.rect[1:2] .= max.(1, round.(Int, b.c .- d.min_radius::Float64))
        d.rect[3:4] .= min.(d.h, round.(Int, b.c .+ d.min_radius::Float64))
        return b
    end
end


