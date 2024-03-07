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
const nleds = prefs["arena"]["nleds"]
const camera_distance = prefs["detection"]["camera_distance"]

# include(joinpath(@__DIR__, "..", "..", "server/DancingQueen/src/suns.jl"))
tocolor(d::AbstractDict) = Color((reinterpret(N0f8, UInt8(get(d, c, 0))) for c in ("red", "green", "blue"))...)

include("functions.jl")

file = "/home/yakir/data/2024-03-07T15:39:03.103 Crazy.log"
# file = last(readdir("../data", join=true))
df, nleds, ring_r, nsuns, colors = get_df(file)


fig = Figure()
intsld = IntervalSlider(fig[3, 1:3], range = 1:nrow(df), startvalues = (1, min(100, nrow(df))))

intsldtxt = lift(intsld.interval) do (i1, i2)
    string(format_time(df.time[i1]), " - ", format_time(df.time[i2]))
end
Label(fig[4, :], intsldtxt, tellwidth = false)
rng = @lift UnitRange($(intsld.interval)...)
lst = lift(last, rng)
ax = Axis(fig[1:2,1:2], aspect = AxisAspect(1), alignmode=Inside())
hidespines!(ax)
hidedecorations!(ax)
lines!(ax, Circle(zero(Point2f), ring_r), color = :gray)
# poly!(ax, Circle(zero(Point2f), ring_r), color = :gray95)
scatter!(ax, zero(Point2f); color = :black, markerspace=:data, markersize=ring_r/10, marker = '+')
lines!(ax, @lift(df.position[$rng]); color = @lift(1:length($rng)), colormap = [(:red, 0.1), (:red, 1.0)])
# scatter!(ax, @lift(df.position[$rng]); color = @lift(1:length($rng)), colormap = [(:red, 0.1), (:red, 1.0)], markerspace=:data, markersize=ring_r/10, marker = '→', rotations = @lift(df.θ[$rng]))
scatter!(ax, @lift(df.position[$lst]); color = :red, markerspace=:data, markersize=ring_r/10, marker = '→', rotations = @lift(df.θ[$lst]))
sun_col = Observable(zeros(RGBA{N0f8}, nleds))
scatter!(ax, index2coordinate.(1:nleds, nleds, ring_r); color = sun_col)
on(lst) do i
    fill!(sun_col[], zero(RGBA{N0f8}))
    for nsun in 1:nsuns
        leds = df[i, "sun$nsun"]
        for j in leds
            sun_col[][j] = RGBA{N0f8}(colors[nsun], 1)
        end
    end
    notify(sun_col)
end

ax1 = PolarAxis(fig[1, 3], title = "Bearing", rlimits=(0, Dates.value(last(df.ms))), thetalimits=(-π, π), rgridwidth=0, thetagridwidth=0, rticklabelcolor=:transparent)
for nsun in 1:nsuns
    hist!(ax1, @lift(first.(df[$rng, string("bearing", nsun)])), color=df[1, "sun$nsun"].color, strokewidth=1, strokecolor=:gray95)
end
on(rng) do _
    autolimits!(ax1)
end
ax2 = PolarAxis(fig[2, 3], title = "Turn", theta_as_x=false, rlimits=(0, Dates.value(last(df.ms))), thetalimits=(-π, π), rgridwidth=0, thetagridwidth=0, rticklabelcolor=:transparent)
rθ = lift(rng) do rng
    Point2f.(Dates.value.(df.ms[rng]), df.θ[rng])
end
lines!(ax2, rθ)
text!(ax2, (0,0), text=@lift(string(round(sum(diff(df.θ[$rng]))/2π, digits=2))), align=(:center, :center))
