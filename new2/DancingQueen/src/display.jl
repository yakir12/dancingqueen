struct Frame{N}
    smaller::Matrix{RGB{N0f8}}
    ring_radius::Float64
    marker_radius::Int
    c::SV
    colors::NTuple{N, Color}
    indices::Vector{Int}
    function Frame{N}(cam, suns) where N
        w, h = size(cam)
        ci = CartesianIndices((1:2:w, 1:2:h))
        li = LinearIndices((w, h))
        indices = vec(li[ci])
        smaller = RGB{N0f8}.(cam.img[ci])
        ring_radius = 0.45min(w, h)/2
        marker_radius = round(Int, ring_radius*sin(π/nleds)/2) # marker radius sized such that the LEDs touch each other around the ring
        c = SV(w/4, h/4)
        colors = NTuple{N, Color}(getfield.(suns, :color))
        new(smaller, ring_radius, marker_radius, c, colors, indices)
    end
end
Frame(cam, suns::NTuple{N, Sun}) where {N} = Frame{N}(cam, suns)

topoint(p) = Point(reverse(Tuple(round.(Int, p))))

function index2point(index, c, ring_radius)
    θ = 2π/nleds*index
    p = ring_radius*SV(reverse(sincos(θ))) + c
    return topoint(p)
end

collect_indices(i1, i2) = i1 ≤ i2 ? collect(i1:i2) : [i1:nleds; 1:i2]

(f::Frame)(::Nothing) = nothing
(f::Frame)(beetle::Beetle) = draw!(f.smaller, CirclePointRadius(topoint(beetle.c/2), f.marker_radius), Color(1, 0, 1))

function (f::Frame)(img, beetle, leds)
    for (i1, i2) in enumerate(f.indices) 
        f.smaller[i1] = RGB(img[i2])
    end
    f(beetle)
    for ((i1, i2), color) in zip(iterate_leds_indices(leds), f.colors), i in collect_indices(i1, i2)
        draw!(f.cimg, CirclePointRadius(index2point(i, f.c, f.ring_radius), f.marker_radius), color)
    end
    return f.cimg
end


