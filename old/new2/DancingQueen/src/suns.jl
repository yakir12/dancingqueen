tofixed(c::UInt8) = reinterpret(N0f8, c)
tocolor(d::AbstractDict) = Color((tofixed(UInt8(get(d, c, 0))) for c in ("red", "green", "blue"))...)

struct Sun
    link_factor::Float64
    color::Color
    θ::Float64
    width::Int
    Sun(link_factor, width, color, θ) = new(link_factor, color, θ, width)
end
Base.zero(::Type{Sun}) = Sun(0, 1, zero(Color), 0)

function Sun(d::AbstractDict)
    link_factor = d["link_factor"]
    width = get(d, "width", 1)
    color = tocolor(d)
    θ = deg2rad(get(d, "azimuth", 0))
    Sun(link_factor, width, color, θ)
end

