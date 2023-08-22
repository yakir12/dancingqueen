module Viewer
using GenieFramework
# using .Main.App.StatisticAnalysis
@genietools

const baseurl = "/frame"

@app begin
    @in refresh = false
    @out imageurl = baseurl

    @onchange refresh begin
        imageurl = string(baseurl, Base.time_ns())
        sleep(0.1)
        refresh = !refresh
    end
end

end
