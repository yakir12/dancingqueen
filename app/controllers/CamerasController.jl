module CamerasController

using GenieFramework
using LinearAlgebra
using ImageDraw, Colors, CoordinateTransformations, Rotations, StaticArrays, JpegTurbo
import Colors.N0f8
import Main: SV, w, h, get_θ

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


function draw_arrow!(img, c::SV, θ)
    trans = topoint ∘ Translation(c) ∘ LinearMap(Angle2d(θ))
    draw!(img, ImageDraw.Path(trans.(arrow_template.body)), RGB{N0f8}(1, 0, 0))
    draw!(img, ImageDraw.Path(trans.(arrow_template.head)), RGB{N0f8}(1, 0, 0))
end
draw_arrow!(img, ::Nothing) = nothing
draw_arrow!(img, b) = draw_arrow!(img, b.c, get_θ(b))

function get_led_template()
    n = 40
    radius1 = 0.95*w/2
    p0 = SV.(reverse.(sincos.(range(-2π/n/2, 2π/n/2, 10))))
    p1 = radius1 * p0
    # radius2 = 0.98*w/2
    # p2 = radius2 * reverse(p0)
    # p = [p1; p2; p1[1:1]]
    # seed = (radius1 + radius2)/2*SV(reverse(sincos(0)))
    return p1
end

const arrow_template = get_arrow()
const led_template = get_led_template()

function draw_led!(img, led)
    # ledc = center(led)
    θ = atan(led[2], led[1])
    trans = topoint ∘ Translation(SV(w/2, h/2)) ∘ LinearMap(Angle2d(θ))
    draw!(img, ImageDraw.Path(trans.(led_template)), RGB{N0f8}(0, 1, 0))
    #
    # draw!(img, CirclePointRadius(ImageDraw.Point(reverse(topoint(led))), 5), RGB{N0f8}(0,1,0))
    #
    # x, y = Tuple(trans(seed))
    # draw!(img, Polygon(tp), colorant"green")
    # draw!(img, CirclePointRadius(x, y, 5), colorant"green")
    # draw!(img, CartesianIndex.(tp), BoundaryFill(y, x; fill_value = colorant"green", boundary_value = colorant"blue"); closed = true)
    # draw!(img, CartesianIndex.(reverse.(tp)), BoundaryFill(x, y; fill_value = colorant"green", boundary_value = colorant"blue"); closed = true)
end


function frame()
    (; img, beetle) = read_state()
    imgcopy = RGB{N0f8}.(Gray{N0f8}.(img))
    draw_arrow!(imgcopy, beetle)
    led = get_led(beetle)
    draw_led!(imgcopy, led)
    respond(String(jpeg_encode(imgcopy)), :jpg)
end

end
