module LogBooks

using Dates
import Tar
import ..Beetle, ..Track, ..SV, ..Sun, ..TrackedSun, ..RGB

export log_record, set_recording, get_recordings

log_print(c::SV) = string(c.x, ",", c.y)

log_print(b::Beetle) = string(log_print(b.c), ",", b.θ)

log_print(c::RGB) = string(Int(reinterpret(c.r)), ",", Int(reinterpret(c.g)), ",", Int(reinterpret(c.b)))

log_print(s::Sun) = string(s.link_factor, ",", s.width, ",", log_print(s.color), ",", s.δ)

log_print(ts::TrackedSun) = string(ts.θ, ",", log_print(ts.sun))

mutable struct LogBook
    io::IOStream
    recording::Bool
    function LogBook()
        io = open(tempname(), "w")
        close(io)
        new(io, false)
    end
end

# function get_fieldnames(T)
#     fields = String[]
#     for f in fieldnames(T)
#         R = fieldtype(T, f)
#         if isempty(fieldnames(R))
#             push!(fields, string(f))
#         else
#             push!(fields, get_fieldnames(R))
#         end
#     end
#     return join(fields, ",")
# end

const logbook = LogBook()

log_record(::Nothing, _) = nothing

function log_record(beetle, tsuns)
    if logbook.recording 
        println(logbook.io, now(), ",", log_print(beetle), ",\"", join(log_print.(tsuns), ","), "\"")
    end
    return nothing
end

function set_recording(is_recording)
    if is_recording
        file = joinpath("data", string(now(), ".log"))
        logbook.io = open(file, "w")
        preamble = read("preferences.toml", String)
        print(logbook.io, preamble)
        println(logbook.io, "time,x,y,θ,tsuns")
        logbook.recording = true
    else
        logbook.recording = false
        close(logbook.io)
    end
end

function get_recordings()
    set_recording(false)
    io = IOBuffer()
    Tar.create("data", io)
    msg = String(take!(io))
    close(io)
    return msg
end

function cleanup(timer)
    cutoff = floor(now(), Week(1)) - Week(1)
    for file in readdir("data")
        name, _ = splitext(file)
        dt = DateTime(name)
        if dt < cutoff
            rm(joinpath("data", file))
        end
    end
end

Timer(cleanup, 0; interval = 604800) # clean up once a week

end
