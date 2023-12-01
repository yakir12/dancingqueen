"""
Each setup should have a label and at least 1 sun. The label cannot be `Off` (that is reserved as an off-button). Each sun should have a link_factor (a number that ranges from minus infinity to plus infinity; typically -1 -- 1) and at least one color intensity (an integer between 0 and 255). Each sun can have width (an odd integer between 1 and the number of LEDs in the strip, and defaults to 1), and color intensities (defaults to 0).

See the [`settings.toml` file](settings.toml) for example.
"""

tocolor(c::Int) = reinterpret(N0f8, UInt8(c))

function Sun(d::AbstractDict)
    link_factor = d["link_factor"]
    width = get(d, "width", 1)
    color = Color((tocolor(get(d, c, 0)) for c in ("red", "green", "blue"))...)
    θ = deg2rad(get(d, "azimuth", 0))
    Sun(link_factor, width, color, θ)
end

Setup(d::AbstractDict) = Setup(d["label"], Sun.(d["suns"]))

