module LEDs

import Main: Beetle

export get_led

const link_factor = Ref(0.0)
const old = Ref((; led = 0.0, beetle1 = 0.0))

get_led(::Nothing) = old[].led

get_led(b::Beetle) = get_led(b.θ)

function get_led(beetle2)
    led, beetle1 = old[]
    Δ = beetle2 - beetle1
    Δ += Δ > π ? -2π : Δ < -π ? 2π : 0
    led += link_factor[]*Δ
    old[] = (; led, beetle1 = beetle2)
    return led
end

end
