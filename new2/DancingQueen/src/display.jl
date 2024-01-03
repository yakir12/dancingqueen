struct Frame{N}
    smaller::Matrix{RGB{N0f8}}
    buffer::Matrix{RGB{N0f8}}
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
        buffer = similar(smaller)
        ring_radius = 0.45min(w, h)/2
        marker_radius = round(Int, ring_radius*sin(π/nleds)) # marker radius sized such that the LEDs touch each other around the ring
        c = SV(w/4, h/4)
        colors = NTuple{N, Color}(getfield.(suns, :color))
        new(smaller, buffer, ring_radius, marker_radius, c, colors, indices)
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
(f::Frame)(beetle::Beetle) = draw!(f.buffer, CirclePointRadius(topoint(beetle.c/2), f.marker_radius), Color(1, 0, 1))

function (f::Frame)(img, beetle, leds, rect)
    for (i1, i2) in enumerate(f.indices) 
        f.buffer[i1] = RGB(img[i2])
    end
    f(beetle)
    for ((i1, i2), color) in zip(iterate_leds_indices(leds), f.colors), i in collect_indices(i1, i2)
        draw!(f.buffer, CirclePointRadius(index2point(i, f.c, f.ring_radius), f.marker_radius), color)
    end
    rect2 = rect .÷ 2
    x1, y1 = max.(1, rect2[1:2])
    x2, y2 = rect2[3:4]
    draw!(f.buffer, RectanglePoints(y1, x1, y2, x2), isnothing(beetle) ? Color(0,1,0) : Color(1,0,0))
    f.smaller .= f.buffer
    # return f.smaller
end


