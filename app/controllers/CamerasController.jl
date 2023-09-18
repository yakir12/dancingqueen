module CamerasController

using GenieFramework
using LinearAlgebra
using ImageDraw, Colors, CoordinateTransformations, Rotations, StaticArrays, JpegTurbo
import Colors.N0f8
import Main: SV, w, h, nleds

using .Main.Monitor
using .Main.LEDs

export frame 

topoint(p) = reverse(Tuple(round.(Int, p)))

function get_arrow()
    l = h/10
    butt = l * SV(-1/2, 0)
    head = l * SV(1/2, 0)
    left = l * SV(-1/sqrt(2)/4 + 1/2, 1/sqrt(2)/4)
    right = l * SV(-1/sqrt(2)/4 + 1/2, -1/sqrt(2)/4)
    return (; body = [butt, head], head = [left, head, right])
end


function draw_arrow!(img, c, θ)
    trans = topoint ∘ Translation(c) ∘ LinearMap(Angle2d(θ))
    draw!(img, ImageDraw.Path(trans.(arrow_template.body)), RGB{N0f8}(1, 0, 0))
    draw!(img, ImageDraw.Path(trans.(arrow_template.head)), RGB{N0f8}(1, 0, 0))
end
draw_arrow!(img, ::Nothing) = nothing
draw_arrow!(img, b) = draw_arrow!(img, b.c, b.θ)

const arrow_template = get_arrow()

function draw_led!(img, leds)
    for led in leds
        θ = 2π/nleds*led
        R = 0.45w
        p = R*SV(reverse(sincos(θ))) + SV(w/2, h/2)
        draw!(img, CirclePointRadius(ImageDraw.Point(topoint(p)), round(Int, R*sin(π/nleds))), RGB{N0f8}(LEDs.red[], LEDs.green[], LEDs.blue[]))
    end
end

function frame()
    (; img, beetle, leds) = read_state()
    imgcopy = RGB{N0f8}.(Gray{N0f8}.(img))
    draw_arrow!(imgcopy, beetle)
    draw_led!(imgcopy, leds)
    respond(String(jpeg_encode(imgcopy)), :jpg)
end

end
