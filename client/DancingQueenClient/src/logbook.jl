mutable struct LogBook
    file::String
    datetime::DateTime
    save::Bool
    transform::Float64
    function LogBook(setup)
        save = setup["label"] ≠ "Off"
        if save
            datetime = now()
            file = joinpath(path2data, string(datetime, " ", setup["label"], ".log"))
            open(file, "w") do io
                preamble = read(path2preferences, String)
                println(io, preamble)
                TOML.print(io, Dict("setup" => setup, "experiment" => Dict("datetime" => datetime)))
                println(io)
                println(io, "ms,x,y,theta,", join(["start$i,stop$i" for i in 1:length(setup["suns"])], ","))
            end
            cm = CamMode(setup)
            transform = get_transform(cm)
        else
            datetime = DateTime(0)
            file = ""
            transform = 0.0
        end
        new(file, datetime, save, transform)
    end
end

log_beetle(::Nothing, _) = ",,"
log_beetle(b, transform) = string(transform*b.c[1], ",", transform*b.c[2], ",", b.theta)

log_leds(leds) = join((string(i1, ",", i2) for (i1, i2) in leds), ",")

log_print(logbook::LogBook, state) = logbook.save && open(logbook.file, "a") do io
    println(io, Dates.value(DateTime(state.datetime, Dates.ISODateTimeFormat) - logbook.datetime), ",", log_beetle(state.beetle, logbook.transform), ",", log_leds(state.leds))
end

function get_transform(cm)
    fov = get_camera_fov(cm)
    h = Int(cm)
    2camera_distance*tand(fov/2)/h
end
