module MonitorController

using GenieFramework
using .Main.Monitor

@genietools

const baseurl = "/frame"

const refresh = Observable(true)

Timer(1; interval = 0.1) do _
    refresh[] = !refresh[]
end

@app begin
    @in recording_on = false
    @out recording_label = "Not recording"
    @out imageurl = baseurl

    @onchange refresh begin
        imageurl = string(baseurl, "#", Base.time_ns())
    end

    @onchange recording_on begin
        recording_label = recording_on ? "Recording" : "Not recording"
        turn_recording!(recording_on)
    end
end

end

