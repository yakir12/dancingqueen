import TOML
using LinearAlgebra, Dates
using CSV, DataFrames, CoordinateTransformations, StaticArrays
using GLMakie
import ColorTypes: RGB, N0f8, RGBA
using Missings

const SV = SVector{2, Float64}
const Color = RGB{N0f8}

const path2preferences = joinpath(@__DIR__, "..", "..", "setup.toml")
const prefs = TOML.parsefile(path2preferences)
const camera_distance = prefs["detection"]["camera_distance"]

# include(joinpath(@__DIR__, "..", "..", "server/DancingQueen/src/suns.jl"))
tocolor(d::AbstractDict) = Color((reinterpret(N0f8, UInt8(get(d, c, 0))) for c in ("red", "green", "blue"))...)

include("functions.jl")
file = "/home/yakir/data/2024-03-14T20:23:17.499 Camera width 2464.log"
# file = last(readdir("../data", join=true))
df, ring, nsuns, colors = get_df(file)


fig = Figure()
intsld = IntervalSlider(fig[3, 1:3], range = 1:nrow(df), startvalues = (1, min(100, nrow(df))))
intsldtxt = lift(intsld.interval) do (i1, i2)
    string(format_time(df.time[i1]), " - ", format_time(df.time[i2]))
end
Label(fig[4, :], intsldtxt, tellwidth = false)
rng = @lift UnitRange($(intsld.interval)...)
lst = lift(last, rng)
ax = Axis(fig[1:2,1:2], aspect = AxisAspect(1), alignmode=Inside(), xlabel="X (cm)", ylabel="Y (cm)")
hidespines!(ax)
# hidedecorations!(ax)
lines!(ax, Circle(zero(Point2f), ring.r), color = :gray)
lines!(ax, Circle(zero(Point2f), 50), color = :gray)
lines!(ax, Circle(zero(Point2f), 30), color = :gray)
# poly!(ax, Circle(zero(Point2f), ring.r), color = :gray95)
scatter!(ax, zero(Point2f); color = :black, markerspace=:data, markersize=ring.r/10, marker = '+')
lines!(ax, @lift(df.position[$rng]); color = @lift(1:length($rng)), colormap = [(:red, 0.1), (:red, 1.0)])
# scatter!(ax, @lift(df.position[$rng]); color = @lift(1:length($rng)), colormap = [(:red, 0.1), (:red, 1.0)], markerspace=:data, markersize=ring.r/10, marker = '→', rotations = @lift(df.θ[$rng]))
scatter!(ax, @lift(df.position[$lst]); color = :red, markerspace=:data, markersize=ring.r/10, marker = '→', rotations = @lift(df.θ[$lst]))
sun_col = Observable(zeros(RGBA{N0f8}, ring.n))
scatter!(ax, [coordinate(ring, i) for i in 1:ring.n]; color = sun_col)
on(lst) do i
    fill!(sun_col[], zero(RGBA{N0f8}))
    for nsun in 1:nsuns
        start = df[i, "start$nsun"]
        stop = df[i, "stop$nsun"]
        for j in ring[start, stop]
            sun_col[][j] = RGBA{N0f8}(colors[nsun], 1)
        end
    end
    notify(sun_col)
end
ax1 = PolarAxis(fig[1, 3], title = "Bearing", rlimits=(0, last(df.ms)), thetalimits=(-π, π), rgridwidth=0, thetagridwidth=0, rticklabelcolor=:transparent)
for nsun in 1:nsuns
    hist!(ax1, @lift(first.(df[$rng, string("bearing", nsun)])), color=colors[nsun], strokewidth=1, strokecolor=:gray95)
end
on(rng) do _
    autolimits!(ax1)
end
ax2 = PolarAxis(fig[2, 3], title = "Turn", theta_as_x=false, rlimits=(0, last(df.ms)), thetalimits=(-π, π), rgridwidth=0, thetagridwidth=0, rticklabelcolor=:transparent)
rθ = lift(rng) do rng
    Point2f.(df.ms[rng], df.θ[rng])
end
lines!(ax2, rθ)
text!(ax2, (0,0), text=@lift(string(round(sum(diff(df.θ[$rng]))/2π, digits=2))), align=(:center, :center))
