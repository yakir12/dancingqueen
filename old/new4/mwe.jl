# So here is a MWE where a container of an image is updated in the background once every second. The client refreshes the image url and thus retrieing the contents of the container - a very fast operation - once every second. 
# This still results in the neverending "Connecting to..." and "Waiting on..." messages.

# ```julia
using ColorTypes
using JpegTurbo
using Genie
using GenieFramework
Genie.config.cdn_enabled = false
@genietools

# return an image
function snap() 
    img = rand(Gray, 480, 480)
    encoded_img = jpeg_encode(img)
    String(encoded_img)
end

# container for the image
frame = Ref(snap())

# continuously and independently update the container
Threads.@spawn while true
    frame[] = snap()
    sleep(1)
end

# return the contents of the container super fast
route("/frame") do
    frame[]
end

@app begin 
    @out imageurl = "/frame"
end 

@methods """updateimage: async function () { this.imageurl = "frame#" + new Date().getTime() }"""

@created "setInterval(this.updateimage, 1000)"

ui() = [imageview(src=:imageurl, basic=true)]

@page("/", ui)

# Server.up()
Server.up(8010, "0.0.0.0", async=false)

# ```
