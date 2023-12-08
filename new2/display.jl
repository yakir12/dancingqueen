struct Frame
    cimg
    ring_radius::Float64
    marker_radius::Int
    c::SV
    function Frame(cam) 
        cimg = RGB.(cam.img)
        w, h = size(cam)
        ring_radius = 0.45min(w, h)
        marker_radius = round(Int, ring_radius*sin(π/nleds)) # marker radius sized such that the LEDs touc each other around the ring
        c = SV(w/2, h/2)
        new(cimg, ring_radius, marker_radius, c)
    end
end

topoint(p) = Point(reverse(Tuple(round.(Int, p))))

function index2point(index, c, ring_radius)
    θ = 2π/nleds*index
    p = ring_radius*SV(reverse(sincos(θ))) + c
    return topoint(p)
end

iterate_indices(i1, i2) = i1 < i2 ? (i1:i2) : [i2:nleds; 1:i1]

function (f::Frame)(img)
    f.cimg .= RGB.(img)
end

(f::Frame)(::Nothing) = nothing
(f::Frame)(beetle::Beetle) = draw!(f.cimg, CirclePointRadius(topoint(beetle.c), f.marker_radius), Color(1, 0, 1))

function (f::Frame)(leds::LEDs{N}) where {N}
    for ((i1, i2), color) in zip(iterate_leds_indices(leds), iterate_leds_colors(leds)), i in iterate_indices(i1, i2)
        draw!(f.cimg, CirclePointRadius(index2point(i, f.c, f.ring_radius), f.marker_radius), color)
    end
end

function (f::Frame)(img, beetle, leds)
    f(img)
    f(beetle)
    f(leds)
    return f.cimg
end


