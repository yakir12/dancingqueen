const ring_radius = 0.45min(w, h)
const marker_radius = round(Int, ring_radius*sin(π/nleds)) # marker radius sized such that the LEDs touc each other around the ring

topoint(p) = Point(reverse(Tuple(round.(Int, p))))

function index2point(index)
    θ = 2π/nleds*index
    p = ring_radius*SV(reverse(sincos(θ))) + SV(w/2, h/2)
    return topoint(p)
end

drawbeetle!(img, ::Nothing) = nothing
function drawbeetle!(img, beetle::Beetle) 
    draw!(img, CirclePointRadius(topoint(beetle.c), marker_radius), Color(1, 0, 1))
end
function drawleds!(img, leds)
    for ls in leds, i in ls
        draw!(img, CirclePointRadius(index2point(i), marker_radius), ls.color)
    end
end

function _get_frame(img, beetle, leds)
    cimg = RGB.(reinterpret.(N0f8, img))
    drawbeetle!(cimg, beetle)
    drawleds!(cimg, leds)
    return cimg
end

