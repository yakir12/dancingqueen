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
    @onchange recording_on begin
        recording_label = recording_on ? "Recording" : "Not recording"
        turn_recording!(recording_on)
    end

    @out imageurl = baseurl
    @onchange refresh imageurl = string(baseurl, "#", Base.time_ns())

    @in link_factor = 0.0
    @onchange link_factor LEDs.link_factor[] = link_factor

    @in red = 0.0
    @onchange red LEDs.red[] = red
    @in green = 0.0
    @onchange green LEDs.green[] = green
    @in blue = 0.0
    @onchange blue LEDs.blue[] = blue

    @in sun_width = 1
    @onchange sun_width LEDs.sun_width[] = sun_width
end

end

