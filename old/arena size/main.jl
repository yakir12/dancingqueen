using CoordinateTransformations

const r = 105 # cm
const h = r
n = 100

function sample(distance)
    beetle = CartesianFromPolar()(Polar(distance, 2π*rand()))
    y = beetle.y
    θ1 = asin(y/r)
    sun = CartesianFromPolar()(Polar(r, θ1))
    δs = range(-π, π, n + 1)[1:end-1]
    θs = Vector{Float64}(undef, n)
    for (i, δ) in enumerate(δs)
        suni = CartesianFromPolar()(Polar(r, θ1+δ))
        beetle2sun = suni - beetle
        θs[i] = atan(reverse(beetle2sun)...)
    end
    a = diff(θs) .- step(δs)
    for i in eachindex(a)
        a[i] += a[i] > π ? -2π : a[i] < -π ? 2π : 0
    end
    Δ = maximum(abs, a)
end

distance = range(0, r, 1000)
E = sample.(distance)

i = findfirst(>(deg2rad(6)), E)
e = round(Int, distance[i])

@show "The maximal radial distance (from the arena's center), where the worst angular error of the sun is bellow 6°, is at $e cm for a link factor of 1"

