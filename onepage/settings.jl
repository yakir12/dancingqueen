import ..DancingQueen.Track.TrackedSun
import ColorTypes: RGB, N0f8

"""
Each setup should have a label and at least 1 sun. Each sun should have a link_factor (a number that ranges from minus infinity to plus infinity; typically -1 -- 1) and at least one color intensity (an integer between 0 and 255). Each sun can have width (an odd integer between 1 and the number of LEDs in the strip, and defaults to 1), and color intensities (defaults to 0).

See the [`settings.toml` file](settings.toml) for example.
"""
const schema = Schema(read("schema.json", String))

tocolor(c::Int) = reinterpret(N0f8, UInt8(c))

function TrackedSun(d::AbstractDict)
    link_factor = d["link_factor"]
    width = get(d, "width", 1)
    color = RGB{N0f8}((tocolor(get(d, c, 0)) for c in ("red", "green", "blue"))...)
    azimuth = deg2rad(get(d, "azimuth", 0))
    TrackedSun(azimuth, DancingQueen.Sun(link_factor, width, color))
end

struct Setup
    label::String
    tsuns::Vector{TrackedSun}
end

const setup_off = Setup("a:Off", [trackedsun_zero()])

function Setup(key, d::AbstractDict)
    label = string(key, ": ", d["label"])
    tsuns = TrackedSun.(d["suns"])
    Setup(label, tsuns)
end

function try2settings(settings)
    dict = TOML.parse(settings)
    msg = validate(schema, dict)
    if !isnothing(msg)
        return msg
    else
        setups = splat(Setup).(zip('b':'z', dict["setups"]))
        pushfirst!(setups, setup_off)
        return setups
    end
end

# txt = read("settings.toml", String)
# setups = try2settings(txt)
