module LogBooks

using Dates
import Tar
import ..Beetle

export log_record, set_recording, get_recordings

mutable struct LogBook
    io::IOStream
    l::ReentrantLock
    recording::Bool
    function LogBook()
        io = open(tempname(), "w")
        # println(io, "time,", get_fieldnames(Beetle), ",tsuns")
        close(io)
        l = ReentrantLock()
        new(io, l, false)
    end
end

function get_fieldnames(T)
    fields = String[]
    for f in fieldnames(T)
        R = fieldtype(T, f)
        if isempty(fieldnames(R))
            push!(fields, string(f))
        else
            push!(fields, get_fieldnames(R))
        end
    end
    return join(fields, ",")
end

const logbook = LogBook()

log_record(::Nothing, _) = nothing

function log_record(beetle, tsuns)
    @info "logging start"
    if logbook.recording 
        @info "is recording"
        @lock logbook.l println(logbook.io, now(), ",", log_print(beetle), ",\"", join(log_print.(tsuns), ","), "\"")
        @info "done recording"
    end
    @info "logging end"
    return nothing
end

function set_recording(is_recording)
    if is_recording
        file = joinpath("data", string(now(), ".log"))
        logbook.io = open(file, "w")
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
