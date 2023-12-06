using JSONSchema, TOML
schema = Schema("""{
            "properties": {
                "foo": {},
                "bar": {}
            },
            "required": ["foo", "bar"]
        }""")
dict = Dict("foo" => 1)
validate(schema, dict)

dict = Dict("setups" => [Dict("label" => "ff", "suns" => [Dict("red" => 1, "link_factor" => 1)])])
schema = Schema(read("schema.json", String))
validate(schema, dict)
