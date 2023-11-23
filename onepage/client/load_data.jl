import TOML
using CSV, DataFrames, Colors, FixedPointNumbers

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


file = last(readdir("/home/yakir/from github/dancingqueen/onepage/data", join=true))
prefs, df = load_data(file)

