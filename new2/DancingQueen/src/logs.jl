mutable struct LogBook
    io::IOStream
    datetime::DateTime
    function LogBook(setup)
        datetime = now()
        file = joinpath(path2data, string(datetime, " ", setup["label"], ".log"))
        io = open(file, "w")
        preamble = read(path2preferences, String)
        println(io, preamble)
        TOML.print(io, Dict("setup" => setup, "experiment" => Dict("datetime" => datetime)))
        println(io)
        println(io, "ms,x,y,θ,", join(["start$i,stop$i" for i in 1:length(setup["suns"])], ","))
        new(io, datetime)
    end
end

function Base.close(logbook::LogBook)
    close(logbook.io)
end

log_print(c::SV) = string(c.x, ",", c.y)

log_print(::Nothing) = ",,"
log_print(b::Beetle) = string(log_print(b.c), ",", b.θ)

# log_print(c::RGB) = string(Int(reinterpret(c.r)), ",", Int(reinterpret(c.g)), ",", Int(reinterpret(c.b)))

log_print(leds::LEDs) = join((string(i1, ",", i2) for (i1, i2) in iterate_leds_indices(leds)), ",")

log!(logbook, beetle, leds) = Threads.@spawn println(logbook.io, Dates.value(now() - logbook.datetime), ",", log_print(beetle), ",", log_print(leds))


