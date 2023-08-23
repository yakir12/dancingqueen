module CamerasController

# using GenieFramework.Genie.Renderer.Html
# using GenieFramework.Genie.Requests
using .Main.App.Cameras
using PNGFiles

export frame 

# function index()
#     html("<h1>Welcome to the number analysis module</h1>
#           <a href=/form>Numbers form</a>")
# end

function frame()
    io = IOBuffer()
    PNGFiles.save(io, Cameras.snap())
    respond(String(take!(io)), :png)
end

end
