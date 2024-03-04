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
                # preamble = read(path2preferences, String)
                # println(io, preamble)
                TOML.print(io, Dict("setup" => setup, "experiment" => Dict("datetime" => datetime)))
                println(io)
                println(io, "ms,x,y,theta,", join(["start$i,stop$i" for i in 1:length(setup["suns"])], ","))
            end
        else
            datetime = DateTime(0)
            file = ""
        end
        camera_distance = 62 # cm, YOU HAVE TO CHANGE THIS TO REALITY!!!
        new(file, datetime, save, get_transform(camera_distance, get(setup, "camera", 1080)))
    end
end

log_beetle(::Nothing, _) = ",,"
log_beetle(b, transform) = string(transform*b.c[1], ",", transform*b.c[2], ",", b.theta)

log_leds(leds) = join((string(i1, ",", i2) for (i1, i2) in leds), ",")

log_print(logbook::LogBook, state) = logbook.save && open(logbook.file, "a") do io
    println(io, Dates.value(DateTime(state.datetime, Dates.ISODateTimeFormat) - logbook.datetime), ",", log_beetle(state.beetle, logbook.transform), ",", log_leds(state.leds))
end


get_camera_fov(h::Int) = 
    h == 480 ? 480/1232*48.8 :
    h == 1232 ? 48.8 :
    h == 1080 ? 1080/2464*48.8 :
    h == 2464 ? 48.8 :
    throw(ArgumentError("Wrong `h = $h`. Should be one of $(Int.(instances(DancingQueen.CamMode)))"))

function get_transform(camera_distance, h)
    fov = get_camera_fov(h)
    2camera_distance*tand(fov/2)/h
end
