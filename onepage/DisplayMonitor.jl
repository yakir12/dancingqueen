module DisplayMonitor

import TOML
using ImageDraw, JpegTurbo
import ColorTypes: RGB, N0f8

import ..get_state, ..SV

export get_frame

const prefs = TOML.parsefile("preferences.toml")
const nleds = prefs["arena"]["nleds"]
const w = prefs["camera"]["width"]
const h = prefs["camera"]["height"]

# function get_indices(i1, i2)
#     if i1 == i2
#         [i1]
#     elseif i1 < i2
#         collect(i1:i2)
#     else
#         [i1:nleds; 1:i2]
#     end
# end

topoint(p) = Point(reverse(Tuple(round.(Int, p))))

function index2point(index, ring_r)
    θ = 2π/nleds*index
    p = ring_r*SV(reverse(sincos(θ))) + SV(w/2, h/2)
    return topoint(p)
end

drawbeetle!(img, ::Nothing) = nothing
drawbeetle!(img, beetle) = draw!(img, CirclePointRadius(topoint(beetle.c), round(Int, 0.01max(w, h))), RGB{N0f8}(1, 0, 1))

drawleds!(img, ::Nothing) = nothing
function drawleds!(img, leds)
    ring_r = 0.45w
    led_r = round(Int, ring_r*sin(π/nleds))
    for ls in leds, i in ls
        draw!(img, CirclePointRadius(index2point(i, ring_r), led_r), ls.color)
    end
end

function get_frame()
    img, beetle, leds = get_state()
    cimg = RGB.(deepcopy(img))
    drawbeetle!(cimg, beetle)
    drawleds!(cimg, leds)
    String(jpeg_encode(cimg))
end

end
