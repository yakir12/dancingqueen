mutable struct Track{N, M}
    sun_θs::MVector{N, Float64}
    previouse_beetle_θ::Float64
    beetle_Δ::Float64
    link_factors::NTuple{N, Float64}
    leds::LEDs{N, M}
    Track{N, M}(suns::NTuple{N, Sun}) where {N, M} = new(MVector{N, Float64}(getfield.(suns, :theta)), 0, 0, NTuple{N, Float64}(getfield.(suns, :link_factor)), LEDs(baudrate, suns))
end
Track(suns::NTuple{N, Sun}) where {N} = Track{N, 5N}(suns)

function (tracker::Track)(::Nothing)
    tracker.beetle_Δ = 0.0
end

function (tracker::Track)(beetle::Beetle)
    Δ = beetle.theta - tracker.previouse_beetle_θ
    Δ += Δ > π ? -2π : Δ < -π ? 2π : 0
    tracker.beetle_Δ = Δ
    tracker.previouse_beetle_θ = beetle.theta
end

function update_suns!(tracker) 
    tracker.sun_θs .+= tracker.link_factors .* tracker.beetle_Δ
    tracker.leds(tracker.sun_θs)
end
