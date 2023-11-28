using GLMakie, CoordinateTransformations, LinearAlgebra, DataFrames

angle(p1, p2) = atan(det(hcat(p1, p2)), p1 ⋅ p2)

const r = 105 # cm
const h = r

# fig = Figure()
# ax = Axis(fig[1,1], aspect=AxisAspect(1))
# lines!(ax, Circle(zero(Point2f), r))
# for i in 1:1
function sample()
    distance = r*rand()
    beetle = CartesianFromPolar()(Polar(distance, 2π*rand()))
    sun = CartesianFromPolar()(Polar(r, 2π*rand()))
    θ = PolarFromCartesian()(sun - beetle).θ
    to_sun = Vec2f(cos(θ), sin(θ))
    beetle_θ = 2π*rand()
    beetle_direction = Vec2f(cos(beetle_θ), sin(beetle_θ))
    Δ = angle(beetle_direction, to_sun)
    return (; distance, Δ)
    # scatter!(ax, Point2f[beetle, sun])
    # arrows!(ax, [Point2f(beetle)], [to_sun]; fxaa=true, # turn on anti-aliasing
    # linecolor = :gray, arrowcolor = :black,
    # linewidth = 3, lengthscale=13)
end

df = DataFrame((sample() for _ in 1:10000))

scatter(df.distance, df.Δ)


function get_bearing(beetle, θ, sun)
    s = SphericalFromCartesian()(CartesianFromSpherical()(sun) - CartesianFromSpherical()(beetle))
    s.θ -θ
end
function sample(br, r, h)
    beetle = Spherical(br, 2π*rand(), 0)
    sun = Spherical(sqrt(r^2 + h^2), 2π*rand(), π/4)
    # n = 1000
    # θs = range(0, 2π, n + 1)[1:end-1]
    # return [get_bearing(beetle, θ, sun) for θ in θs]
end

hist(rad2deg.(sample(r, h)), axis = (; limits=((-360, 360),nothing)))
