mutable struct LogBook
    io::IOStream
    recording::Bool
    function LogBook()
        io = open(tempname(), "w")
        close(io)
        new(io, false)
    end
end

print_row(::Nothing) = ",,"
print_row(b) = string(b.c[1], ",", b.c[2], ",", b.θ)

function log!(logbook, beetle, leds)
    logbook.recording && println(logbook.io, now(), ",", print_row(beetle), ",", leds)
end

function turn!(logbook, is_recording)
    if is_recording
        file = joinpath("data", string(now(), ".log"))
        logbook.io = open(file, "w")
        println(logbook.io, "t,x,y,θ,led")
        logbook.recording = true
    else
        logbook.recording = false
        close(logbook.io)
    end
end
