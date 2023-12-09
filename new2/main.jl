import TOML
using DancingQueen
using Observables
import ColorTypes: RGB, N0f8

const Color = RGB{N0f8}

txt = read("settings.toml", String)
setups = TOML.parse(txt)

setup = Observable(Dict("label" => "Off", "suns" => [Dict("link_factor" => 0)]))
setup[] = setups["setups"][2]

img = Ref(rand(Color, 10, 10))

main(setup, img)



