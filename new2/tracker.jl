mutable struct Track{N}
    sun_θs::MVector{N, Float64}
    previouse_beetle_θ::Float64
    beetle_Δ::Float64
    Track{N}(suns::SVector{N, Sun}) where {N} = new(MVector{N, Float64}(getfield.(suns, :θ)), 0, 0)
end
Track(suns::SVector{N, Sun}) where {N} = Track{N}(suns)

function (tracker::Track)(::Nothing)
    tracker.beetle_Δ = 0.0
end

function (tracker::Track)(beetle::Beetle)
    Δ = beetle.θ - tracker.previouse_beetle_θ
    Δ += Δ > π ? -2π : Δ < -π ? 2π : 0
    tracker.beetle_Δ = Δ
    tracker.previouse_beetle_θ = beetle.θ
end

function (tracker::Track{N})(suns::SVector{N, Sun}) where {N}
    for (i, sun) in enumerate(suns)
        tracker.sun_θs[i] += sun.link_factor * tracker.beetle_Δ
    end
end

