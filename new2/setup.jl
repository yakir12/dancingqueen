tofixed(c::UInt8) = reinterpret(N0f8, c)
tocolor(d::AbstractDict) = Color((tofixed(UInt8(get(d, c, 0))) for c in ("red", "green", "blue"))...)

struct Sun
    link_factor::Float64
    width::Int
    color::Color
    θ::Float64
    r::Int
    Sun(link_factor, width, color, θ) = new(link_factor, width, color, θ, (width - 1)/2)
end
Base.zero(::Type{Sun}) = Sun(0, 1, zero(Color), 0)

struct Setup{N}
    label::String
    suns::SVector{N, Sun}
    Setup{N}(label, suns::SVector{N}) where {N} = new(label, suns)
end
Setup(label, suns::SVector{N, Sun}) where {N} = Setup{N}(label, suns)

Base.zero(::Type{Setup}) = Setup{1}("Off", SVector{1, Sun}(zero(Sun)))

function Sun(d::AbstractDict)
    link_factor = d["link_factor"]
    width = get(d, "width", 1)
    color = tocolor(d)
    θ = deg2rad(get(d, "azimuth", 0))
    Sun(link_factor, width, color, θ)
end
Setup(d::AbstractDict) = Setup(d["label"], SVector((Sun(sun) for sun in d["suns"])...))

