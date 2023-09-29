"""
Each setup should have a label and at least 1 sun. Each sun should have a link_factor (a number that ranges from minus infinity to plus infinity; typically -1 -- 1) and at least one color intensity (an integer between 0 and 255). Each sun can have width (an odd integer between 1 and the number of LEDs in the strip, and defaults to 1), and color intensities (defaults to 0).

See the [`settings.toml` file](settings.toml) for example.
"""

const schema = Schema("""{
"type": "object",
"properties": {
    "setups": {
        "type": "array",
        "items": {
            "type": "object",
            "properties": {
                "label": {
                    "type": "string",
                    "maxLength": 60
                },
                "suns": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "anyOf": [
                                {"required": ["red", "link_factor"]},
                                {"required": ["green", "link_factor"]},
                                {"required": ["blue", "link_factor"]}
                            ],
                        "properties": {
                            "link_factor": {
                                "type": "number"
                            },
                            "width": {
                                "type": "integer",
                                "minimum": 1,
                                "maximum": 100,
                                "not": {"multipleOf": 2}
                            },
                            "red": {
                                "type": "integer",
                                "minimum": 0,
                                "maximum": 255
                            },
                            "green": {
                                "type": "integer",
                                "minimum": 0,
                                "maximum": 255
                            },
                            "blue": {
                                "type": "integer",
                                "minimum": 0,
                                "maximum": 255
                            }
                        }
                    },
                    "minItems": 1,
                    "uniqueItems": true
                }
            },
            "required": [ "suns", "label" ]
        },
        "minItems": 1,
        "maxItems": 26,
        "uniqueItems": true
    },
"required": [ "setups" ]
}
}""")

struct Sun
    link_factor::Float64
    width::Int
    color::RGB{N0f8}
    θ::Float64
end

function Sun(d::AbstractDict)
    link_factor = d["link_factor"]
    width = get(d, "width", 1)
    color = RGB((get(d, c, 0)/255 for c in ("red", "green", "blue"))...)
    Sun(link_factor, width, color, 0.0)
end

Sun() = Sun(0, 1, zero(RGB{N0f8}), 0.0)

struct Setup
    label::String
    suns::Vector{Sun}
end

function Setup(d::AbstractDict)
    label = d["label"]
    suns = Sun.(d["suns"])
    Setup(label, suns)
end

Setup() = Setup("default", [Sun()])

function try2settings(settings)
    dict = TOML.parse(settings)
    msg = validate(schema, dict)
    return isnothing(msg) ? Setup.(dict["setups"]) : msg
end

# txt = read("settings.toml", String)
# setups = try2settings(txt)
