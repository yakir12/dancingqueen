mutable struct LogBook
    file::String
    datetime::DateTime
    save::Bool
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
        new(file, datetime, save)
    end
end

log_beetle(::Nothing) = ",,"
log_beetle(b) = string(b.c[1], ",", b.c[2], ",", b.theta)

log_leds(leds) = join((string(i1, ",", i2) for (i1, i2) in leds), ",")

log_print(logbook::LogBook, state) = logbook.save && open(logbook.file, "a") do io
    println(io, Dates.value(DateTime(state.datetime, Dates.ISODateTimeFormat) - logbook.datetime), ",", log_beetle(state.beetle), ",", log_leds(state.leds))
end
