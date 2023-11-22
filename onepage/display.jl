module DisplayMonitor


function get_indices(i1, i2)
    if i1 == i2
        [i1]
    elseif i1 < i2
        collect(i1:i2)
    else
        [i1:nleds; 1:i2]
    end
end

topoint(p) = reverse(Tuple(round.(Int, p)))

drawbeetle!(img, ::Nothing) = nothing
drawbeetle!(img, beetle) = draw!(img, CirclePointRadius(Point(topoint(beetle.c)), round(Int, 0.01max(w, h))), RGB{N0f8}(1, 0, 1))

function ImageDraw.draw!(img, ls::LEDStrip)
    R = 0.45w
    for index in get_indices(ls.i1, ls.i2)
        θ = 2π/nleds*index
        p = R*SV(reverse(sincos(θ))) + SV(w/2, h/2)
        draw!(img, CirclePointRadius(ImageDraw.Point(topoint(p)), round(Int, R*sin(π/nleds))), ls.color)
    end
end

function get_frame()
    img, beetle, tsuns = get_state()
    cimg = RGB.(deepcopy(img))
    drawbeetle!(cimg, beetle)
    for ts in tsuns
        ls = LEDStrip(ts)
        draw!(cimg, ls)
    end
    String(jpeg_encode(cimg))
end

end
