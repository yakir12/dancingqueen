using GLMakie, CoordinateTransformations, LinearAlgebra, DataFrames, Rotations

angle(p1, p2) = atan(det(hcat(p1, p2)), p1 ⋅ p2)

const r = 105 # cm
const h = r

fig = Figure()
ax = Axis(fig[1,1], aspect=DataAspect())
lines!(ax, Circle(zero(Point2f), r), color = :gray)
for i in 1:1
# function sample()
    distance = 0.5*r#*rand()
    beetle = CartesianFromPolar()(Polar(distance, 2π*rand()))
    sun = CartesianFromPolar()(Polar(r, 2π*rand()))
    beetle2sun = sun - beetle
    beetle_θ = deg2rad(90)#2π*rand()
    beetle_direction1 = Vec2f(cos(beetle_θ), sin(beetle_θ))
    bearing1 = angle(beetle_direction1, beetle2sun)
    @show rad2deg(bearing1)
    Δ_beetle = deg2rad(45)#π*(2rand() - 1)
    beetle_direction2 = LinearMap(Angle2d(Δ_beetle))(beetle_direction1)
    bearing2 = angle(beetle_direction2, beetle2sun)
    @show rad2deg(bearing2)
    Δ = bearing1 - Δ_beetle - bearing2
    @show rad2deg(Δ)
    # return (; distance, Δ)
    scatter!(ax, Point2f[beetle, sun])
    arrows!(ax, [Point2f(beetle)], [beetle2sun]; fxaa=true, linecolor = :black, arrowcolor = :black, linewidth = 1, lengthscale=0.95)
    arrows!(ax, [Point2f(beetle)], [beetle_direction1]; fxaa=true, linecolor = :green, arrowcolor = :green, linewidth = 1, lengthscale=r/2)
    arrows!(ax, [Point2f(beetle)], [beetle_direction2]; fxaa=true, linecolor = :blue, arrowcolor = :blue, linewidth = 1, lengthscale=r/2)
    # arrows!(ax, [Point2f(beetle)], [Vec2f(reverse(sincos(beetle_θ + bearing1)))]; fxaa=true, linecolor = :blue, arrowcolor = :blue, linewidth = 1, lengthscale=10)
    # arrows!(ax, [Point2f(beetle)], [beetle_direction2]; fxaa=true, linecolor = :green, arrowcolor = :green, linewidth = 1, lengthscale=10)
    # arrows!(ax, [Point2f(beetle)], [Vec2f(reverse(sincos(beetle_θ + bearing1 + Δ_beetle)))]; fxaa=true, linecolor = :red, arrowcolor = :red, linewidth = 1, lengthscale=15)
end

df = DataFrame((sample() for _ in 1:100))

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
