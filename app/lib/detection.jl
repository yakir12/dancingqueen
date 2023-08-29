const SV = SVector{2, Float64}
tag_pixel_width = 45#37
const min_radius = tag_pixel_width/sqrt(2)
const widen_radius = 5

struct Rect
    i1::Int
    i2::Int
    j1::Int
    j2::Int
    function Rect(i1::Int, i2::Int, j1::Int, j2::Int)
        i1 = max(1, i1)
        j1 = max(1, j1)
        i2 = min(w, i2)
        j2 = min(h, j2)
        new(i1, i2, j1, j2)
    end
end
Rect() = Rect(1, w, 1, h)


function get_rect(c)
    i1, j1 = round.(Int, c .- min_radius)
    i2, j2 = round.(Int, c .+ min_radius)
    Rect(i1, i2, j1, j2)
end

function oneiter(detector, buff, img, rect)
    # crop the image to the past rectangle
    img[] = @view buff[rect.i1:rect.i2, rect.j1:rect.j2]
    # detect
    tags = detector(collect(img[]))
    if length(tags) ≠ 1 # not found
        # widen the rectangle
        Rect(rect.i1 - widen_radius, rect.i2 + widen_radius, rect.j1 - widen_radius, rect.j2 + widen_radius)
    else # found
        tag = only(tags)
        # center
        c = SV(reverse(tag.H[1:2,3])) + SV(rect.i1, rect.j1)
        # direction
        d = normalize(sum(p -> SV(reverse(p)) - c, tag.p[1:2]))
        # update the LED strip
        @async send2strip(c, d)
        # update the rectangle
        get_rect(c)
    end
end

send2strip(c, d) = nothing

