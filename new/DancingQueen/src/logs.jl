mutable struct LogBook
    io::IOStream
    recording::Bool
    function LogBook()
        io = open(tempname(), "w")
        close(io)
        new(io, false)
    end
end

function close_log!(logbook)
    logbook.recording = false
    close(logbook.io)
end

function open_log!(logbook, setup)
    file = joinpath(path2data, string(now(), " ", setup.label, ".log"))
    logbook.io = open(file, "w")
    preamble = read(path2preferences, String)
    println(logbook.io, preamble)
    TOML.print(logbook.io, Dict("setup" => JSON3.read(JSON3.write(setup), Dict)))
    println(logbook.io)
    println(logbook.io, "datetime,x,y,θ,", join(["start$i,stop$i,red$i,green$i,blue$i" for i in 1:length(setup.suns)], ","))
    logbook.recording = true
end

log_print(c::SV) = string(c.x, ",", c.y)

log_print(b::Beetle) = string(log_print(b.c), ",", b.θ)

log_print(c::RGB) = string(Int(reinterpret(c.r)), ",", Int(reinterpret(c.g)), ",", Int(reinterpret(c.b)))

log_print(ls::LEDSun) = string(ls.i1, ",", ls.i2, ",", log_print(ls.color))

log!(logbook, beetle, leds) = logbook.recording && println(logbook.io, now(), ",", log_print(beetle), ",", join(log_print.(leds), ","))

function get_recordings()
    close_log()
    io = IOBuffer()
    Tar.create(path2data, io)
    msg = String(take!(io))
    close(io)
    return msg
end

# function cleanup(timer)
#     cutoff = floor(now(), Week(1)) - Week(1)
#     for file in readdir("data")
#         name, _ = splitext(file)
#         dt = DateTime(name)
#         if dt < cutoff
#             rm(joinpath("data", file))
#         end
#     end
# end
#
# Timer(cleanup, 0; interval = 604800) # clean up once a week

