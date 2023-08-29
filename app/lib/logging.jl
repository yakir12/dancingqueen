struct LogBook
    io::Ref{IOStream}
    recording::Observable{Bool}
    function LogBook()
        recording = Observable(false)
        io = Ref{IOStream}(open(tempname(), "w"))
        close(io[])
        on(recording) do is_recording
            if is_recording
                file = joinpath("data", string(now(), ".log"))
                io[] = open(file, "w")
            else
                close(io[])
            end
        end
        new(io, recording)
    end
end

function turn(onoff)
    camera[].logbook.recording[] = onoff
end


