const link_factor = Ref(0.0)
const sun_color = Ref(zero(RGB{N0f8}))
const sun_width = Ref(1)
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

α2led(α) = round(Int, nleds*α/2π + 0.5)

function α2leds(α)
    δ = (sun_width[] - 1)*π/nleds
    α1 = mod(α - δ, 2π)
    α2 = mod(α + δ, 2π)
    return α2led(α1), α2led(α2)
end

function get_leds(beetle)
    led1, led2 = α2leds(get_led(beetle))
    if led1 == led2
        [led1]
    elseif led1 < led2
        led1:led2
    else
        [led1:nleds; 1:led2]
    end
end
