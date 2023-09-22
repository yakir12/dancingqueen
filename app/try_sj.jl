using JpegTurbo, Observables, VideoIO

using GenieFramework
@genietools

cam = opencamera()
img = Ref(read(cam))
const msg = Ref{String}()
const w = size(img[], 1)
const fps = 30

# fetch fresh frames from the camera as quickly as possible
Threads.@spawn while isopen(cam)
    read!(cam, img[])
    sleep(1/2fps)
end

# avoid writing to disk
route("/frame") do
    String(jpeg_encode(img[]))
end

@app WebCam begin
    @out imageurl = "/frame"
end myhandlers

ui() = [imageview(src=:imageurl, basic=true, style="max-width: $(w)px")]

model = init(WebCam, debounce = 0) |> myhandlers

Stipple.js_methods(model::WebCam) = """
    updateimage: async function () { 
        this.imageurl = "frame#" + new Date().getTime()
    }
"""

# Stipple.js_created(model::WebCam) = """
#     setInterval(() => {
#     this.updateimage();
#     }, 33);
# """

# Stipple.js_created(model::WebCam) = """
# (function loop() {
#   setTimeout(() => {
#     () => this.updateimage;
#     loop();
#   }, 100);
# })();
# """

Stipple.js_created(model::WebCam) = "setInterval(this.updateimage, 33)"# $(round(Int, 5*1000/fps)))"

route("/") do
    global model

    page(model, ui) |> html
end

up()
