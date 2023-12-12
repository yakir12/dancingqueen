import TOML
using DancingQueen
setup, img = main();

txt = read("settings.toml", String);
setups = TOML.parse(txt)["setups"];
push!(setups,  Dict("label" => "Off", "suns" => [Dict("link_factor" => 0)]));

# setup[] = setups[2]


# Threads.@spawn for i in 1:100
#     setup[] = rand(setups)
# end
#
# Threads.@spawn for i in 1:100
#     setup[] = rand(setups)
# end
#
setup[] = setups[4]

using JpegTurbo
using GenieFramework
@genietools

# avoid writing to disk, when the user asks for a frame they get the latest one
route("/frame") do
    respond(String(jpeg_encode(img[])), :jpg)
end

@app Webcam begin
    @out imageurl = "/frame"
end myhandlers

global model = init(Webcam, debounce = 0) |> myhandlers

# add an (invalid) anchor to the imagepath in order to trigger a reload in the Quasar/Vue backend
Stipple.js_methods(model::Webcam) = """updateimage: async function () { this.imageurl = "frame#" + new Date().getTime() }"""

# have the client update the image every 33 milliseconds (should be changed to the camera's actual 1000/fps or less)
Stipple.js_created(model::Webcam) = "setInterval(this.updateimage, 1000)"

# set the image style to basic to avoid the loading wheel etc
ui() = [imageview(src=:imageurl, basic=true)]

route("/") do
    page(model, ui) |> html
end

Server.up(8000, "0.0.0.0")
