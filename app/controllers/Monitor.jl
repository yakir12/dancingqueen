module Monitor

using GenieFramework
using .Main.App.Cameras

@genietools

const baseurl = "/frame"

const refresh = Observable(true)

Timer(1; interval = 0.1) do _
    refresh[] = !refresh[]
end

@app begin
    @out imageurl = baseurl
    @in record = false
    @out recording_label = "Not recording"

    @onchange refresh begin
        imageurl = string(baseurl, "#", Base.time_ns())
    end

    @onchange record begin
        recording_label = record ? "Recording" : "Not recording"
        LogBooks.recording[] = record
    end
end

end

