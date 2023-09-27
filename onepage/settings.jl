using TOML
using JSONSchema

txt = """
[[setups]]

label = "one stationary green sun"

[[setups.suns]]
link_factor=0
green=255
width=1

[[setups]]

label = "two different suns"

[[setups.suns]]
link_factor=-0.2
blue=100
width=3

[[setups.suns]]
link_factor=1
red=255
width=11
"""

dict = TOML.parse(txt)


my_schema = Schema(raw"""{
                   "required": [ "setups", "label", "suns" ],
                   "type": "array",
                   "items": { "$ref": "#/$defs/veggie" }
                   "$defs": {
                    "veggie": {
      "type": "object",
      "required": [ "veggieName", "veggieLike" ],
      "properties": {
        "veggieName": {
          "type": "string",
          "description": "The name of the vegetable."
        },
                   "properties": {
                     "latitude": {
                        "type": "number",
                        "minimum": -90,
                        "maximum": 90
                        },
                     "longitude": {
                        "type": "number",
                        "minimum": -180,
                        "maximum": 180
                        }
                    }
                   }""")


txt = """{
  "latitude": 4888.858093,
  "longitude": 2.294694
  }
"""
data_pass = Dict(JSON3.read(txt))

validate(my_schema, data_pass)
