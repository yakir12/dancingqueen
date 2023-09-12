module LogBooks

using Dates
import Main.print_row

export LogBook, log!, turn!

mutable struct LogBook
    io::IOStream
    recording::Bool
    function LogBook()
        io = open(tempname(), "w")
        close(io)
        new(io, false)
    end
end

log!(logbook, ::Nothing) = nothing

function log!(logbook, beetle)
    Threads.@spawn(logbook.recording && println(logbook.io, now(), ",", print_row(beetle)))
end

function turn!(logbook, is_recording)
    if is_recording
        file = joinpath("data", string(now(), ".log"))
        logbook.io = open(file, "w")
        println(logbook.io, "t,x,y,θ")
        logbook.recording = true
    else
        logbook.recording = false
        close(logbook.io)
    end
end

end
