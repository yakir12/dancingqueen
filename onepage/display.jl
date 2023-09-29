topoint(p) = reverse(Tuple(round.(Int, p)))

ImageDraw.draw!(img, ::Nothing) = nothing
ImageDraw.draw!(img, b::Beetle) = draw!(img, CirclePointRadius(Point(topoint(b.c)), round(Int, 0.01max(w, h))), RGB{N0f8}(1, 0, 1))

function ImageDraw.draw!(img, ledss::Vector{LEDs})
    R = 0.45w
    for leds in ledss, index in leds.indices
        θ = 2π/nleds*index
        p = R*SV(reverse(sincos(θ))) + SV(w/2, h/2)
        draw!(img, CirclePointRadius(ImageDraw.Point(topoint(p)), round(Int, R*sin(π/nleds))), leds.color)
    end
end

function get_frame()
    cimg = RGB.(deepcopy(img[]))
    draw!(cimg, beetle[])
    draw!(cimg, leds[])
    String(jpeg_encode(cimg))
end
