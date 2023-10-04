"""
Each setup should have a label and at least 1 sun. Each sun should have a link_factor (a number that ranges from minus infinity to plus infinity; typically -1 -- 1) and at least one color intensity (an integer between 0 and 255). Each sun can have width (an odd integer between 1 and the number of LEDs in the strip, and defaults to 1), and color intensities (defaults to 0).

See the [`settings.toml` file](settings.toml) for example.
"""
const schema = Schema(read("schema.json", String))

function DancingQueen.Sun(d::AbstractDict)
    link_factor = d["link_factor"]
    width = get(d, "width", 1)
    color = RGB((get(d, c, 0)/255 for c in ("red", "green", "blue"))...)
    Sun(link_factor, width, color)
end

DancingQueen.Sun() = Sun(0, 1, zero(RGB{N0f8}))

struct Setup
    label::String
    suns::Vector{Sun}
end

Setup() = Setup("Off", [Sun()])

function Setup(d::AbstractDict)
    label = d["label"]
    suns = Sun.(d["suns"])
    Setup(label, suns)
end

const setup = Ref(Setup())

function try2settings(settings)
    dict = TOML.parse(settings)
    msg = validate(schema, dict)
    if !isnothing(msg)
        return msg
    else
        setups = Setup.(dict["setups"])
        pushfirst!(setups, Setup())
        return setups
    end
end

# txt = read("settings.toml", String)
# setups = try2settings(txt)
