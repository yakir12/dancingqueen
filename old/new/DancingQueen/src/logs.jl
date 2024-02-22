mutable struct LogBook
    io::IOStream
    recording::Bool
    datetime::DateTime
    function LogBook()
        io = open(tempname(), "w")
        close(io)
        new(io, false, now())
    end
end

function close_log!(logbook)
    logbook.recording = false
    close(logbook.io)
end

function open_log!(logbook, setup)
    logbook.datetime = now()
    file = joinpath(path2data, string(logbook.datetime, " ", setup.label, ".log"))
    logbook.io = open(file, "w")
    preamble = read(path2preferences, String)
    println(logbook.io, preamble)
    TOML.print(logbook.io, Dict("setup" => JSON3.read(JSON3.write(setup)), "experiment" => Dict("datetime" => logbook.datetime)))
    println(logbook.io)
    println(logbook.io, "ms,x,y,θ,", join(["start$i,stop$i,red$i,green$i,blue$i" for i in 1:length(setup.suns)], ","))
    logbook.recording = true
end

log_print(c::SV) = string(c.x, ",", c.y)

log_print(::Nothing) = ",,"
log_print(b::Beetle) = string(log_print(b.c), ",", b.θ)

log_print(c::RGB) = string(Int(reinterpret(c.r)), ",", Int(reinterpret(c.g)), ",", Int(reinterpret(c.b)))

log_print(ls::LEDSun) = string(ls.i1, ",", ls.i2, ",", log_print(ls.color))

log!(logbook, beetle, leds) = logbook.recording && println(logbook.io, Dates.value(now() - logbook.datetime), ",", log_print(beetle), ",", join(log_print.(leds), ","))

