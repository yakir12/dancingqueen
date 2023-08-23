module App
using GenieFramework
include("lib/Cameras.jl")
include("controllers/AnalysisController.jl")
using .Cameras
using .AnalysisController



# TODO: fix the width w thing, it should be correct


# fps = 10
# w, h = (640, 480)
# cmd = `libcamera-vid -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`

# TODO: move this into the model somehow, to control the on off


# kill(o)

port = 8080
host = "192.168.80.2"
const BASEURL = "http://$host:$port"

@genietools

@app begin
    @in refresh = false
    @out imageurl = string(BASEURL, "/frame")

    @onchange refresh begin
        imageurl = string(BASEURL, "/frame#", Base.time_ns())
        sleep(0.1)
        refresh = !refresh
    end
end

function ui()
    [ 
     button("Start",  @click("refresh = !refresh"))
     imageview(src=:imageurl, basic=true, style="height: 140px; max-width: 150px")
    ]
end

@page("/", ui)

route(frame, "/frame")

Server.up(port, host)












route("/", AnalysisController.index)

route("/form") do
    html(Renderer.filepath("pages/form.jl.html"))
end

route("/form", AnalysisController.analysis,  method=POST)

route("/numbers/:N::Int", AnalysisController.numbers)


    end

# the model part
@app begin
    @in x = 1
    @out y = 2

    @onchange x begin
        y = 2x
    end
end

# the view part
function ui()
    [
    # ...
    ]
end

@page("/", ui)

