module CamerasController

using GenieFramework
import .Main.App.Cameras
using PNGFiles

export frame 

function frame()
    io = IOBuffer()
    PNGFiles.save(io, Cameras.last_frame())
    respond(String(take!(io)), :png)
end

end
