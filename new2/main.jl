import TOML
using DancingQueen

setup, img, i = main()

txt = read("settings.toml", String)
setups = TOML.parse(txt)
setup[] = setups["setups"][4]

# setup[] = setups["setups"][2]

using JpegTurbo
using GenieFramework
@genietools

# a convinience function to convert pixel matrices to jpegs
to_frame = String ∘ jpeg_encode

# avoid writing to disk, when the user asks for a frame they get the latest one
route("/frame") do
    to_frame(img[])
end

@app Webcam begin
    @out imageurl = "/frame"
end myhandlers

global model = init(Webcam, debounce = 0) |> myhandlers

# add an (invalid) anchor to the imagepath in order to trigger a reload in the Quasar/Vue backend
Stipple.js_methods(model::Webcam) = """updateimage: async function () { this.imageurl = "frame#" + new Date().getTime() }"""

# have the client update the image every 33 milliseconds (should be changed to the camera's actual 1000/fps or less)
Stipple.js_created(model::Webcam) = "setInterval(this.updateimage, 67)"

# set the image style to basic to avoid the loading wheel etc
ui() = [imageview(src=:imageurl, basic=true)]

route("/") do
    page(model, ui) |> html
end

Server.up()
