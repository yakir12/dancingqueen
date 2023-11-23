import TOML
using CSV, DataFrames, Colors, FixedPointNumbers
using CoordinateTransformations, StaticArrays, AngleBetweenVectors

const SV = SVector{2, Float64}

struct LEDSun
    i1::Int
    i2::Int
    color::RGB{N0f8}
end

function Base.iterate(ls::LEDSun, state=ls.i1)
    if ls.i2 < ls.i1
        state > nleds + ls.i2 - 1 ? nothing : (1 + rem(state - 1, nleds - 1), state + 1)
    else
        state > ls.i2 ? nothing : (state, state + 1)
    end
end

function center(ls::LEDSun, nleds)
    if ls.i2 < ls.i1
        m = ls.i1 + Int((ls.i2 + nleds - ls.i1) / 2)
        m > nleds ? m - nleds : m
    else
        ls.i1 + Int((ls.i2 - ls.i1) / 2)
    end
end

tocolor(txt::AbstractString) = reinterpret(N0f8, parse(UInt8, txt))
tocolor(txts::AbstractArray) = RGB{N0f8}(map(tocolor, txts)...)

function parse_leds(row)
    xss = split(row, ',')
    if rem(length(xss), 5) ≠ 0
        @warn "Skipping faulty row" row
        return missing
    end
    nleds = Int(length(xss)/5)
    ys = Vector{LEDSun}(undef, nleds)
    for (i, xs) in enumerate(Iterators.partition(xss, 5))
        ys[i] = LEDSun(parse(Int, xs[1]), parse(Int, xs[2]), tocolor(xs[3:5]))
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
    # df = CSV.read(file, DataFrame, skipto=16)
    transform!(df, :leds => ByRow(parse_leds), renamecols = false)
    dropmissing!(df)
    sort!(df, :time)
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

function get_angles(sun_centers, θ, beetle_xy)
    v = SV(reverse(sincos(θ)))
    n = length(sun_centers)
    ideal = Vector{Float64}(undef, n)
    real = Vector{Float64}(undef, n)
    for (i, sun_center) in enumerate(sun_centers)
        ideal[i] = angle(sun_center, v)
        real[i] = angle(sun_center - beetle_xy, v)
    end
    return (; ideal, real)
end

function main(file)
    prefs, df = load_data(file)
    nleds = prefs["arena"]["nleds"]
    ring_r = 10prefs["arena"]["ring_r"] # in cm
    origo_offset = SV(prefs["arena"]["origo_offset"]...) # in pixels
    cm_per_pixel = prefs["arena"]["cm_per_pixel"]

    transform!(df, [:x, :y] => ByRow((x, y) -> image2realworld(x, y, origo_offset, cm_per_pixel)) => :positions) 
    transform!(df, :leds => ByRow(xs -> index2coordinate.(center.(xs, nleds), nleds, ring_r)) => "sun centers")
    transform!(df, Cols("sun centers", :θ, :positions) => ByRow(get_angles) => AsTable)
    transform!(df, :positions => ByRow(xy -> (; x = xy.x, y = xy.y)) => AsTable)

    df = select(df, Cols(:time, :x, :y, :θ, "sun centers", :ideal, :real)) 
    n = maximum(length.(df.ideal))
    for field in (:ideal, :real, "sun centers")
        transform!(df, field => ByRow(x -> vcat(x, fill(missing, n - length(x)))) => [Symbol("$field$i") for i in 1:n])
    end
    df
end


file = last(readdir("/home/yakir/from github/dancingqueen/onepage/data", join=true))

df = main(file)


# df = DataFrame(a = 1:3, b = [collect(1:i) for i in 1:3])
# n = maximum(length.(df.b))
# transform!(df, :b => ByRow(x -> vcat(x, fill(missing, n - length(x)))) => [Symbol("b$i") for i in 1:n])
# select!(df, Not(:b))

