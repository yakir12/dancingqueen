module LogBooks

using Dates

export log_record, set_recording, get_recordings

mutable struct LogBook
    io::IOStream
    recording::Bool
    function LogBook()
        io = open(tempname(), "w")
        close(io)
        new(io, false)
    end
end

const logbook = LogBook()

function log_record(args...)
    logbook.recording && println(logbook.io, now(), ",", args...)
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
    toggle_recording(false)
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
