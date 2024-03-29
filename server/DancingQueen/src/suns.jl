tocolor(d::AbstractDict) = Color(UInt8(get(d, c, 0)) for c in ("red", "green", "blue"))

struct Sun
    link_factor::Float64
    color::Color
    theta::Float64
    width::Int
    Sun(link_factor, width, color, theta) = new(link_factor, color, theta, width)
end

function Sun(d::AbstractDict)
    link_factor = d["link_factor"]
    width = get(d, "width", 1)
    color = tocolor(d)
    theta = deg2rad(get(d, "azimuth", 0))
    Sun(link_factor, width, color, theta)
end
