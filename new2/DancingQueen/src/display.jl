struct Frame{N}
    cimg
    ring_radius::Float64
    marker_radius::Int
    c::SV
    colors::NTuple{N, Color}
    function Frame{N}(cam, suns) where N
        cimg = RGB.(cam.img)
        w, h = size(cam)
        ring_radius = 0.45min(w, h)
        marker_radius = round(Int, ring_radius*sin(π/nleds)) # marker radius sized such that the LEDs touch each other around the ring
        c = SV(w/2, h/2)
        colors = NTuple{N, Color}(getfield.(suns, :color))
        new(cimg, ring_radius, marker_radius, c)
    end
end
Frame(cam, suns::NTuple{N, Sun}) where {N} = Frame{N}(cam, suns)

topoint(p) = Point(reverse(Tuple(round.(Int, p))))

function index2point(index, c, ring_radius)
    θ = 2π/nleds*index
    p = ring_radius*SV(reverse(sincos(θ))) + c
    return topoint(p)
end

collect_indices(i1, i2) = i1 < i2 ? collect(i1:i2) : [i2:nleds; 1:i1]

(f::Frame)(::Nothing) = nothing
(f::Frame)(beetle::Beetle) = draw!(f.cimg, CirclePointRadius(topoint(beetle.c), f.marker_radius), Color(1, 0, 1))

function (f::Frame)(img, beetle, leds)
    f.cimg .= RGB.(img)
    f(beetle)
    for ((i1, i2), color) in zip(iterate_leds_indices(leds), f.colors), i in collect_indices(i1, i2)
        draw!(f.cimg, CirclePointRadius(index2point(i, f.c, f.ring_radius), f.marker_radius), color)
    end
    return f.cimg
end


