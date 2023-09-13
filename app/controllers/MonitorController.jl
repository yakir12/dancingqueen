module MonitorController

using GenieFramework
using .Main.Monitor
using .Main.LEDs

@genietools

const baseurl = "/frame"

const refresh = Observable(true)

Timer(1; interval = 0.2) do _
    refresh[] = !refresh[]
end

@app begin
    @in recording_on = false
    @out recording_label = "Not recording"
    @out imageurl = baseurl

    @in bearing = 0.0
    @in link_factor = 0.0

    @onchange refresh imageurl = string(baseurl, "#", Base.time_ns())

    @onchange recording_on begin
        recording_label = recording_on ? "Recording" : "Not recording"
        turn_recording!(recording_on)
    end

    @onchange link_factor LEDs.link_factor[] = link_factor
end

end

