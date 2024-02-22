import TOML
using LinearAlgebra, Dates
using CSV, DataFrames, CoordinateTransformations, StaticArrays
using GLMakie
import ColorTypes: RGB, N0f8, RGBA
using Missings

const SV = SVector{2, Float64}
const Color = RGB{N0f8}

const nleds = 100

struct LEDSun
    i1::Int
    i2::Int
    color::Color
end

function Base.iterate(ls::LEDSun, i::Int=ls.i1)
    if i > ls.i2
        nothing
    else
        (mod(i - 1, nleds) + 1, i + 1)
    end
end

Base.length(ls::LEDSun) = ls.i2 - ls.i1 + 1

Base.eltype(::Type{LEDSun}) = Int

middle(ls::LEDSun) = mod((ls.i1 + ls.i2) ÷ 2 - 1, nleds) + 1

angle(p1, p2) = atan(det(hcat(p1, p2)), p1 ⋅ p2)

tocolor(c::Int) = reinterpret(N0f8, UInt8(c))
tocolor(r, g, b) = Color(tocolor(r), tocolor(g), tocolor(b))

tocolor(txt::AbstractString) = reinterpret(N0f8, parse(UInt8, txt))
tocolor(txts::AbstractArray) = RGB{N0f8}(map(tocolor, txts)...)

function parse_leds(row)
    xss = split(row, ',')
    if rem(length(xss), 5) ≠ 0
        @warn "Skipping faulty row" row
        return missing
    end
    n = Int(length(xss)/5)
    ys = Vector{LEDSun}(undef, n)
    for (i, xs) in enumerate(Iterators.partition(xss, 5))
        ys[i] = LEDSun(parse(Int, xs[1]), parse(Int, xs[2]), tocolor(xs[3:5]), nleds)
    end
    return ys
end

get_preamble(file) = open(file, "r") do io
    i = 0
    while !eof(io)
        if startswith(readline(io), "ms")
            return i
        else
            i += 1
        end
    end
end

function load_data(file)
    preamble = get_preamble(file)
    io = open(file, "r")
    toml = ""
    for i in 1:preamble
        toml *= readline(io) * "\n"
    end
    prefs = TOML.parse(toml)
    df = CSV.read(io, DataFrame)
    close(io)
    # transform!(df, :leds => ByRow(row -> parse_leds(row, prefs["arena"]["nleds"])), renamecols = false)
    dropmissing!(df)
    sort!(df, :ms)
    return (prefs, df)
end

function index2coordinate(index, ring_r)
    θ = 2π/nleds*index
    ring_r*SV(reverse(sincos(θ)))
end

function image2realworld(x, y, origo_offset, cm_per_pixel)
    xy = SV(x, y)
    xy -= origo_offset # offset to center
    xy *= cm_per_pixel # scale to real world coordinates
    return xy
end

function get_bearings(sun_center, θ, beetle_xy)
    v = SV(reverse(sincos(θ)))
    return angle(sun_center - beetle_xy, v)
end

function get_df(file)
    prefs, df = load_data(file)
    transform!(df, :ms => ByRow(Millisecond), renamecols=false)
    @assert df.ms[end] - df.ms[1] < Hour(24) "Experiment lasted longer than 24 hours"
    _nleds, ring_r, origo_offset, cm_per_pixel = prefs["arena"]["nleds"], prefs["arena"]["ring_r"], SV(prefs["arena"]["origo_offset"]...), prefs["arena"]["cm_per_pixel"]
    @assert nleds == _nleds "number of LEDs does not match with records"
    transform!(df, :ms => ByRow(ms -> Time(0) + ms) => :time, [:x, :y] => ByRow(passmissing((x, y) -> image2realworld(x, y, origo_offset, cm_per_pixel))) => :position) 
    select!(df, Not(Cols(:x, :y)))
    nsuns = length(names(df, r"start"))
    for i in 1:nsuns
        transform!(df, ["start$i", "stop$i", "red$i", "green$i", "blue$i"] => ByRow((i1, i2, r, g, b) -> LEDSun(i1, i2, tocolor(r, g, b))) => "leds$i")
        transform!(df, "leds$i" => ByRow(xs -> index2coordinate(middle(xs), ring_r)) => "sun_c$i")
        transform!(df, Cols("sun_c$i", :θ, :position) => ByRow(passmissing(get_bearings)) => "bearing$i")
    end
    select!(df, Not(Cols(r"start", r"stop", r"red", r"green", r"blue")))
    return df, nleds, ring_r, nsuns
end

format_time(t::Time) = Dates.format(t, "HH:MM:SS.sss")

file = last(readdir("../data", join=true))
df, nleds, ring_r, nsuns  = get_df(file)


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
        leds = df[i, "leds$nsun"]
        for j in leds
            sun_col[][j] = RGBA{N0f8}(leds.color, 1)
        end
    end
    notify(sun_col)
end
ax1 = PolarAxis(fig[1, 3], title = "Bearing", rlimits=(0, Dates.value(last(df.ms))), thetalimits=(-π, π), rgridwidth=0, thetagridwidth=0, rticklabelcolor=:transparent)
for nsun in 1:nsuns
    hist!(ax1, @lift(first.(df[$rng, string("bearing", nsun)])), color=df[1, "leds$nsun"].color, strokewidth=1, strokecolor=:gray95)
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
