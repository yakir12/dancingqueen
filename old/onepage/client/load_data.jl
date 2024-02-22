import TOML
using LinearAlgebra, Dates
using CSV, DataFrames, Colors, FixedPointNumbers
using CoordinateTransformations, StaticArrays
using GLMakie

const SV = SVector{2, Float64}

angle(p1, p2) = atan(det(hcat(p1, p2)), p1 ⋅ p2)

struct LEDSun
    i1::Int
    i2::Int
    color::RGB{N0f8}
    nleds::Int
    function LEDSun(i1, i2, color, nleds)
        if i1 > i2
            i2 += nleds
        end
        new(i1, i2, color, nleds)
    end
end
# Required method
function Base.iterate(ls::LEDSun, i::Int=ls.i1)
    if i > ls.i2
        nothing
    else
        (mod(i - 1, ls.nleds) + 1, i + 1)
    end
end
# Important optional methods
Base.eltype(::Type{LEDSun}) = Tuple{Int, Int}
Base.length(ls::LEDSun) = ls.i2 - ls.i1 + 1

middle(ls::LEDSun) = Int((ls.i1 + ls.i2)/2)

tocolor(txt::AbstractString) = reinterpret(N0f8, parse(UInt8, txt))
tocolor(txts::AbstractArray) = RGB{N0f8}(map(tocolor, txts)...)

function parse_leds(row, nleds)
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

function load_data(file; preamble=17)
    io = open(file, "r")
    toml = ""
    for i in 1:preamble
        toml *= readline(io) * "\n"
    end
    prefs = TOML.parse(toml)
    df = CSV.read(io, DataFrame)
    transform!(df, :leds => ByRow(row -> parse_leds(row, prefs["arena"]["nleds"])), renamecols = false)
    dropmissing!(df)
    sort!(df, :datetime)
    return (prefs, df)
end

function index2coordinate(index, nleds, ring_r)
    θ = 2π/nleds*index
    ring_r*SV(reverse(sincos(θ)))
end

function image2realworld(x, y, origo_offset, cm_per_pixel)
    xy = SV(x, y)
    xy -= origo_offset # offset to center
    xy *= cm_per_pixel # scale to real world coordinates
    return xy
end

function get_bearings(sun_centers, θ, beetle_xy)
    v = SV(reverse(sincos(θ)))
    return [angle(sun_center - beetle_xy, v) for sun_center in sun_centers]
end

function get_df(file)
    prefs, df = load_data(file)
    @assert df.datetime[end] - df.datetime[1] < Hour(24) "Experiment lasted longer than 24 hours"
    nleds, ring_r, origo_offset, cm_per_pixel = prefs["arena"]["nleds"], prefs["arena"]["ring_r"], SV(prefs["arena"]["origo_offset"]...), prefs["arena"]["cm_per_pixel"]
    transform!(df, :datetime => ByRow(dt -> Time(0) + (dt - df.datetime[1])) => :time, [:x, :y] => ByRow((x, y) -> image2realworld(x, y, origo_offset, cm_per_pixel)) => :position) 
    transform!(df, :leds => ByRow(xs -> index2coordinate.(middle.(xs), nleds, ring_r)) => :sun_c)
    transform!(df, Cols(:sun_c, :θ, :position) => ByRow(get_bearings) => :bearing)
    return df, nleds, ring_r
end

format_time(t::Time) = Dates.format(t, "HH:MM:SS.sss")

# function leds2points(leds, nleds, ring_r)
#     xy = Point2f[]
#     for led in leds, j in led
#         push!(xy, index2coordinate(j, nleds, ring_r))
#     end
#     return xy
# end
#
# function leds2color(leds)
#     c = RGB{N0f8}[]
#     for led in leds, j in led
#         push!(c, led.color)
#     end
#     return c
# end


file = last(readdir("../data", join=true))
df, nleds, ring_r  = get_df(file)

# transform!(df, :leds => ByRow(leds -> [LEDSun(l.i1, l.i1 > l.i2 ? l.i2 + nleds : l.i2, l.color) for l in leds]), renamecols = false)

# n = maximum(length, df.leds)
# fields = (:leds, :sun_c, :bearing)
# for field in fields
#     transform!(df, field => ByRow(x -> vcat(x, fill(missing, n - length(x)))) => [Symbol("$field$i") for i in 1:n])
# end
nsuns = maximum(length, df.leds)
# select!(df, Not(fields...))



fig = Figure()
intsld = IntervalSlider(fig[2, 1:2], range = 1:nrow(df), startvalues = (1, min(100, nrow(df))))
intsldtxt = lift(intsld.interval) do (i1, i2)
    string(format_time(df.time[i1]), " - ", format_time(df.time[i2]))
end
Label(fig[3, :], intsldtxt, tellwidth = false)
rng = @lift UnitRange($(intsld.interval)...)
lst = lift(last, rng)
ax = Axis(fig[1,1], aspect = AxisAspect(1), alignmode=Inside())
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
    for leds in df.leds[i], j in leds
        sun_col[][j] = RGBA{N0f8}(leds.color, 1)
    end
    notify(sun_col)
end





suns_pos = fill(Observable(Point2f[]), nsuns)
suns_col = fill(Observable(RGBA{N0f8}[]), nsuns)
for i in 1:nsuns
    scatter!(ax, suns_pos[i]; color = suns_col[i])
end
on(lst) do i
    for j in 1:nsuns




scatter!(ax, @lift(leds2points(df.leds[$lst], nleds, ring_r)); color = @lift(leds2color(df.leds[$lst])))
ax1 = PolarAxis(fig[1, 2], title = "Bearing")
hist!(ax1, @lift(first.(df.bearing[$rng])))
on(rng) do _
    autolimits!(ax1)
end


fig = Figure()
ax = PolarAxis(fig[1,1])
hist!(ax, 2pi*rand(100))
xs = Observable(pi*rand(100))
color = Observable((:red, 1.0))
hist!(ax, xs; color)
# n = 10
# barplot!(ax, range(0, 2pi, n+1)[1:end-1], 1:n, dodge=isodd.(1:n) .+ 1)





on(sg.sliders[1].value) do ms
    i = findfirst(≥(df.time[1] + Millisecond(ms)), df.time)
    positions[] = [df.position[i]]
    rotations[] = df.θ[i]
    empty!(bearing[])
    append!(bearing[], df.bearing[1:i])
    notify(bearing)
    empty!(sun_positions[])
    empty!(color[])
    empty!(sun_centers[])
    for leds in df.leds[i]
        for j in leds
            xy = index2coordinate(j, nleds, ring_r)
            push!(sun_positions[], xy)
            push!(color[], leds.color)
        end
        for sun_c in df.sun_c[i]
            push!(sun_centers[], Point2f(sun_c))
        end
    end
    notify(sun_positions)
    notify(color)
    notify(sun_centers)
end
display(fig)


#
#
# fig = Figure()
# ax = PolarAxis(fig[1, 1], title = "Default")
# lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#     transform!(df, :position => ByRow(xy -> (; beetle_x = xy.x, beetle_y = xy.y)) => AsTable)
#     transform!(df, "sun centers" => ByRow(xys -> first.(xys))  => :sun_x, "sun centers" => ByRow(xys -> last.(xys))  => :sun_y)
#     df = select(df, Cols(:time, :beetle_x, :beetle_y, :θ, :sun_x, :sun_y, :bearing)) 
#     n = maximum(length.(df.bearing))
#     fields = (:sun_x, :sun_y, :bearing)
#     for field in fields
#         transform!(df, field => ByRow(x -> vcat(x, fill(missing, n - length(x)))) => [Symbol("$field$i") for i in 1:n])
#     end
#     select!(df, Not(fields...))
#     rename!(df, :θ => :beetle_θ)
#     transform!(df, :beetle_θ => ByRow(rad2deg), renamecols = false)
#     df
# end
#



# df = DataFrame(a = 1:3, b = [collect(1:i) for i in 1:3])
# n = maximum(length.(df.b))
# transform!(df, :b => ByRow(x -> vcat(x, fill(missing, n - length(x)))) => [Symbol("b$i") for i in 1:n])
# select!(df, Not(:b))


