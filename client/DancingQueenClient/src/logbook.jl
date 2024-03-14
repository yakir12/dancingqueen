get_servr_datetime(state) = DateTime(state.datetime, Dates.ISODateTimeFormat)
mutable struct LogBook
    file::String
    local_datetime::DateTime
    server_datetime::DateTime
    save::Bool
    transform::Function
    function LogBook(setup, state)
        save = setup["label"] ≠ "Off"
        local_datetime = now()
        server_datetime = get_servr_datetime(state)
        if save
            file = joinpath(path2data, string(local_datetime, " ", setup["label"], ".log"))
            open(file, "w") do io
                preamble = read(path2preferences, String)
                println(io, preamble)
                TOML.print(io, Dict("setup" => setup, "experiment" => Dict("datetime" => local_datetime)))
                println(io)
                nsuns = length(setup["suns"])
                println(io, "ms,x,y,theta,", join(string.("start", 1:nsuns), ","))
            end
            cm = CamMode(setup)
            transform = get_transform(cm)
        else
            file = ""
            transform = xy -> 0 .* xy
        end
        new(file, local_datetime, server_datetime, save, transform)
    end
end

log_beetle(::Nothing, _) = ",,"
function log_beetle(b, transform) 
    x, y = transform(b.c)
    string(x, ",", y, ",", b.theta)
end

log_leds(leds) = join(first.(leds), ",")

log_print(logbook::LogBook, state) = logbook.save && open(logbook.file, "a") do io
    println(io, Dates.value(get_servr_datetime(state) - logbook.server_datetime), ",", log_beetle(state.beetle, logbook.transform), ",", log_leds(state.leds))
end

function get_transform(cm)
    fov = get_camera_fov(cm)
    h = Int(cm)
    xy -> 2camera_distance*tand(fov/2)/h .* (xy .- h/2)
end
