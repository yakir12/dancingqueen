const tb = Ref((previouse_θ = 0.0, Δ = 0.0))

function track(beetle::Beetle)
    Δ = beetle.θ - tb[].previouse_θ
    Δ += Δ > π ? -2π : Δ < -π ? 2π : 0
    tb[] = (; previouse_θ = beetle.θ, Δ)
end

function rotate!(sun::Sun)
    sun.θ += sun.link_factor * tb[].Δ
end




# mutable struct TrackedSun
#     θ::Float64
#     sun::Sun
# end
#
# trackedsun_zero() = TrackedSun(0, Sun(0, 1, zero(RGB{N0f8})))
#
# const tsuns = [trackedsun_zero()]
#
# function set_suns(new_tsuns::Vector{TrackedSun})
#     empty!(tsuns)
#     append!(tsuns, new_tsuns)
# end
#
#
#
# get_leds(::Nothing) = nothing
#
# function get_leds(beetle::Beetle)
#     track!(tb, beetle)
#     for ts in tsuns
#         rotate!(ts, tb)
#     end
#     return LEDSun.(tsuns)
# end
