module CamerasController

using GenieFramework
import .Main.App.Cameras
using PNGFiles

export frame 

function frame()
    io = IOBuffer()
    PNGFiles.save(io, Cameras.snap())
    respond(String(take!(io)), :png)
end

end
