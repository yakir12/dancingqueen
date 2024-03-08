# struct LEDSun
#     i1::Int
#     i2::Int
#     color::Color
# end
#
# function Base.iterate(ls::LEDSun, i::Int=ls.i1)
#     if i > ls.i2
#         nothing
#     else
#         (mod(i - 1, nleds) + 1, i + 1)
#     end
# end
#
# Base.length(ls::LEDSun) = ls.i2 - ls.i1 + 1
#
# Base.eltype(::Type{LEDSun}) = Int
#
# middle(ls::LEDSun) = mod((ls.i1 + ls.i2) ÷ 2 - 1, nleds) + 1
#
#
# tocolor(c::Int) = reinterpret(N0f8, UInt8(c))
# tocolor(r, g, b) = Color(tocolor(r), tocolor(g), tocolor(b))
#
# tocolor(txt::AbstractString) = reinterpret(N0f8, parse(UInt8, txt))
# tocolor(txts::AbstractArray) = RGB{N0f8}(map(tocolor, txts)...)
#
# function parse_leds(row)
#     xss = split(row, ',')
#     if rem(length(xss), 5) ≠ 0
#         @warn "Skipping faulty row" row
#         return missing
#     end
#     n = Int(length(xss)/5)
#     ys = Vector{LEDSun}(undef, n)
#     for (i, xs) in enumerate(Iterators.partition(xss, 5))
#         ys[i] = LEDSun(parse(Int, xs[1]), parse(Int, xs[2]), tocolor(xs[3:5]), nleds)
#     end
#     return ys
# end
#


struct Ring
    n::Int
    r::Float64
end
Base.length(ring::Ring) = ring.n
Base.iterate(ring::Ring, i::Int=1) = (ring[i], i + 1)
Base.eltype(::Type{Ring}) = Int
Base.getindex(ring::Ring, i::Int) = mod(i - 1, ring.n) + 1
function Base.getindex(ring::Ring, left::Int, right::Int)
    if left > right
        right += ring.n
    end
    return (ring[i] for i in left:right)
end
function middle(ring::Ring, left::Int, right::Int)
    if left > right
        right += ring.n
    end
    i = (left + right) ÷ 2
    return ring[i]
end
angle(ring::Ring, i::Int) = 2π/ring.n*ring[i]
coordinate(ring::Ring, i::Int) = ring.r*SV(reverse(sincos(angle(ring, i))))


angle(p1, p2) = atan(det(hcat(p1, p2)), p1 ⋅ p2)



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

function get_bearings(ring, start, stop, θ, beetle_xy)
    sun_center = coordinate(ring, middle(ring, start, stop))
    v = SV(reverse(sincos(θ)))
    return angle(sun_center - beetle_xy, v)
end

function get_df(file)
    prefs, df = load_data(file)
    dropmissing!(df, Cols(r"start", r"stop"))
    dt = prefs["experiment"]["datetime"]
    colors = tocolor.(prefs["setup"]["suns"])
    widths = get.(prefs["setup"]["suns"], "width", 1)
    transform!(df, :ms => ByRow(ms -> Time(dt + Millisecond(ms))) => :time, [:x, :y] => ByRow(passmissing(SV)) => :position, :theta => :θ)
    ring = Ring(prefs["arena"]["nleds"], prefs["arena"]["ring_r"])
    nsuns = length(names(df, r"start"))
    for i in 1:nsuns
        transform!(df, "start$i" => ByRow(start -> start + widths[i] - 1) => "stop$i")
        transform!(df, ["start$i", "stop$i", "θ", "position"] => ByRow((start, stop, θ, position) -> get_bearings(ring, start, stop, θ, position)) => "bearing$i")
    end
    select!(df, Not(Cols(:x, :y, "theta")))
    return df, ring, nsuns, colors
end

format_time(t::Time) = Dates.format(t, "HH:MM:SS.sss")



#
#     @assert df.ms[end] - df.ms[1] < Hour(24) "Experiment lasted longer than 24 hours"
#     _nleds = prefs["arena"]["nleds"]
#     ring_r = prefs["arena"]["ring_r"]
#     @assert nleds == _nleds "number of LEDs does not match with records"
#     # origo_offset = get(prefs["setup"], "camera", 1080) / 2 * SV(1,1)
#     transform!(df, :ms => ByRow(ms -> Time(0) + ms) => :time, [:x, :y] => ByRow(passmissing(SV)) => :position) 
#     select!(df, Not(Cols(:x, :y)))
#     nsuns = length(names(df, r"start"))
#     for i in 1:nsuns
#         transform!(df, ["start$i", "stop$i", "red$i", "green$i", "blue$i"] => ByRow((i1, i2, r, g, b) -> LEDSun(i1, i2, tocolor(r, g, b))) => "leds$i")
#     end
#     select!(df, Not(Cols(r"start", r"stop", r"red", r"green", r"blue")))
#     return df, nleds, ring_r, nsuns
# end
#
#
