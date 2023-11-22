import TOML
using CSV, DataFrames, Colors, FixedPointNumbers

const TSUN = @NamedTuple{θ::Float64, link_factor::Float64, width::Int64, color::RGB{N0f8}, δ::Float64}

tocolor(txt::AbstractString) = reinterpret(N0f8, parse(UInt8, txt))
tocolor(txts::AbstractArray) = RGB{N0f8}(map(tocolor, txts)...)

function parse_tsuns(row)
    xss = split(row, ',')
    if rem(length(xss), 7) ≠ 0
        @warn "Skipping faulty row" row
        return missing
    end
    ntsuns = Int(length(xss)/7)
    ys = Vector{TSUN}(undef, ntsuns)
    for (i, xs) in enumerate(Iterators.partition(xss, 7))
        ys[i] = TSUN((
                      parse(Float64, xs[1]), 
                      parse(Float64, xs[2]), 
                      parse(Int, xs[3]), 
                      tocolor(xs[4:6]),
                      parse(Float64, xs[7])
                     ))
    end
    return ys
end

function load_data(file; preamble=13)
    io = open(file, "r")
    toml = ""
    for i in 1:preamble
        toml *= readline(io) * "\n"
    end
    prefs = TOML.parse(toml)
    df = CSV.read(io, DataFrame)
    # df = CSV.read(file, DataFrame, skipto=16)
    transform!(df, :tsuns => ByRow(parse_tsuns), renamecols = false)
    dropmissing!(df)
    sort!(df, :time)
    return (prefs, df)
end

file = "/home/yakir/projects2/dancing queen/project/onepage/data/2023-11-22T13:36:04.078.log"
prefs, df = load_data(file)

