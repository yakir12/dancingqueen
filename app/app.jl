module App

# const w = 1080
# const h = 1920

using GenieFramework

# include("lib/Detection.jl")
# include("lib/LogBooks.jl")
# include("lib/Cameras.jl")
# include("lib/Monitor.jl")

include("controllers/CamerasController.jl")
include("controllers/MonitorController.jl")


using .CamerasController
using .MonitorController

route(frame, "/frame")

@page("/monitor", "pages/monitorcontroller.jl", Stipple.ReactiveTools.DEFAULT_LAYOUT(), Main.App.MonitorController)

# TODO: fix the width w thing, it should be correct


# fps = 10
# w, h = (640, 480)
# cmd = `libcamera-vid -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`

# TODO: move this into the model somehow, to control the on off


# kill(o)

# port = 8080
# host = "192.168.80.2"
# const BASEURL = "http://$host:$port"
#
# @genietools
#
# @app begin
#     @in refresh = false
#     @out imageurl = string(BASEURL, "/frame")
#
#     @onchange refresh begin
#         imageurl = string(BASEURL, "/frame#", Base.time_ns())
#         sleep(0.1)
#         refresh = !refresh
#     end
# end
#
# function ui()
#     [ 
#      button("Start",  @click("refresh = !refresh"))
#      imageview(src=:imageurl, basic=true, style="height: 140px; max-width: 150px")
#     ]
# end
#
# @page("/", ui)
#
# route(frame, "/frame")
#
# Server.up(port, host)


end









