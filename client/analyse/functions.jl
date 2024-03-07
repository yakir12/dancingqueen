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
# angle(p1, p2) = atan(det(hcat(p1, p2)), p1 ⋅ p2)
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

function get_bearings(sun_center, θ, beetle_xy)
    v = SV(reverse(sincos(θ)))
    return angle(sun_center - beetle_xy, v)
end

function index2coordinate(index, nleds, ring_r)
    θ = 2π/nleds*index
    ring_r*SV(reverse(sincos(θ)))
end

function get_df(file)
    prefs, df = load_data(file)
    dropmissing!(df, Cols(r"start", r"stop"))
    dt = prefs["experiment"]["datetime"]
    colors = tocolor.(prefs["setup"]["suns"])
    widths = get.(prefs["setup"]["suns"], "width", 1)
    transform!(df, :ms => ByRow(ms -> Time(dt + Millisecond(ms))) => :time, [:x, :y] => ByRow(passmissing(SV)) => :position, :theta => :θ)
    nsuns = length(names(df, r"start"))
    ring_r = prefs["arena"]["ring_r"]
    nleds = prefs["arena"]["nleds"]
    for i in 1:nsuns
        transform!(df, "start$i" => ByRow(start -> start : start + widths[i] - 1) => "sun$i")
        transform!(df, "sun$i" => ByRow(xs -> index2coordinate(middle(xs), nleds, ring_r)) => "sun_c$i")
        transform!(df, Cols("sun_c$i", :θ, :position) => ByRow(passmissing(get_bearings)) => "bearing$i")
    end
    select!(df, Not(Cols(:x, :y, r"start", "theta")))
    return df, nleds, ring_r, nsuns, colors
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
