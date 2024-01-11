const disp_w = 300 # less than 500

struct Frame{N}
    smaller::Matrix{Color}
    buffer::Matrix{Color}
    ring_radius::Float64
    marker_radius::Int
    c::SV
    colors::NTuple{N, Color}
    ratio::Float64
    cross::Cross
    function Frame{N}(h, suns) where N
        smaller = zeros(Color, disp_w, disp_w)
        buffer = similar(smaller)
        ratio = disp_w/h
        ring_radius = 0.45h*ratio
        marker_radius = round(Int, ring_radius*sin(π/nleds)) # marker radius sized such that the LEDs touch each other around the ring
        c = ratio*SV(h/2, h/2)
        colors = NTuple{N, Color}(getfield.(suns, :color))
        cross = Cross(topoint(c), round(Int, ratio*h/2))
        new(smaller, buffer, ring_radius, marker_radius, c, colors, ratio, cross)
    end
end
Frame(h::Int, suns::NTuple{N, Sun}) where {N} = Frame{N}(h, suns)

topoint(p) = Point(reverse(Tuple(round.(Int, p))))

function index2point(index, c, ring_radius)
    θ = 2π/nleds*index - π/2
    p = ring_radius*SV(reverse(sincos(θ))) + c
    return topoint(p)
end

collect_indices(i1, i2) = i1 ≤ i2 ? collect(i1:i2) : [i1:nleds; 1:i2]

(f::Frame)(::Nothing) = nothing
(f::Frame)(beetle::Beetle) = draw!(f.buffer, CirclePointRadius(topoint(f.ratio*beetle.c), f.marker_radius), Color(1, 0, 1))

function (f::DancingQueen.Frame)(img, beetle, leds, rect)
    imresize!(f.buffer, img)
    f(beetle)
    for ((i1, i2), color) in zip(iterate_leds_indices(leds), f.colors), i in collect_indices(i1, i2)
        draw!(f.buffer, CirclePointRadius(index2point(i, f.c, f.ring_radius), f.marker_radius), color)
    end
    draw!(f.buffer, f.cross, Color(1,1,1))
    rect2 = round.(Int, f.ratio*rect)
    x1, y1 = max.(1, rect2[1:2])
    x2, y2 = rect2[3:4]
    draw!(f.buffer, RectanglePoints(y1, x1, y2, x2), isnothing(beetle) ? Color(0,1,0) : Color(1,0,0))
    f.smaller .= f.buffer
    # return f.smaller
end


