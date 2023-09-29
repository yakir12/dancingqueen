const old = Ref((; azimuth = 0.0, beetle1 = 0.0))

get_azimuth(::Nothing, ::Float64) = old[].azimuth
get_azimuth(b::Beetle, link_factor::Float64) = get_azimuth(b.θ, link_factor)

function get_azimuth(beetle2::Float64, link_factor::Float64)
    azimuth, beetle1 = old[]
    Δ = beetle2 - beetle1
    Δ += Δ > π ? -2π : Δ < -π ? 2π : 0
    azimuth += link_factor*Δ
    old[] = (; azimuth, beetle1 = beetle2)
    return azimuth
end

α2index(α) = round(Int, nleds*α/2π + 0.5)

function α2indices(α, width)
    δ = (width - 1)*π/nleds
    α1 = mod(α - δ, 2π)
    α2 = mod(α + δ, 2π)
    return α2index(α1), α2index(α2)
end

function get_indices(beetle, sun)
    i1, i2 = α2indices(get_azimuth(beetle, sun.link_factor), sun.width)
    if i1 == i2
        [i1]
    elseif i1 < i2
        i1:i2
    else
        [i1:nleds; 1:i2]
    end
end

struct LEDs
    indices::Vector{Int}
    color::RGB{N0f8}
    LEDs(beetle, sun) = new(get_indices(beetle, sun), sun.color)
end
