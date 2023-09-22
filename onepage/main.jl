using VideoIO, AprilTags, StaticArrays, ImageDraw, CoordinateTransformations, Rotations, JpegTurbo, Colors
import Colors.N0f8

if !isdir("data")
    mkdir("data")
end

const cam = opencamera()
const img = Ref(read(cam))
const w, h = size(img[])
const nleds = 101

include("detection.jl")
include("leds.jl")
include("logbooks.jl")
include("display.jl")

const beetle = Ref{Union{Nothing, Beetle}}(nothing)
const leds = Ref(get_leds(beetle[]))

dr = DetectoRect()
logbook = LogBook()

task = Threads.@spawn while isopen(cam)
    read!(cam, img[])
    beetle[] = dr(img[])
    leds[] = get_leds(beetle[])
    Threads.@spawn log!(logbook, beetle[], leds[])
end

using GenieFramework
@genietools

# avoid writing to disk
route(get_frame, "/frame")

@app WebCam begin
    @out imageurl = "/frame"

    @in recording_on = false
    @out recording_label = "Not recording"
    @onchange recording_on begin
        turn!(logbook, recording_on)
        recording_label = recording_on ? "Recording" : "Not recording"
    end

    @in link_facto = 0.0
    @onchange link_facto link_factor[] = link_facto

    @in red = 0.0
    @onchange red sun_color[] = RGB(red, sun_color[].g, sun_color[].b)
    @in green = 0.0
    @onchange green sun_color[] = RGB(sun_color[].r, green, sun_color[].b)
    @in blue = 0.0
    @onchange blue sun_color[] = RGB(sun_color[].r, sun_color[].g, blue)

    @in sun_widt = 1
    @onchange sun_widt sun_width[] = sun_widt


end myhandlers

ui() = [
        toolbar([
                 btn(@click("redirectToLink(frame)"), flat=true, round=true, dense=true, icon="menu"),
                                       toolbartitle("Toolbar"),
                                       btn(flat=true, round=true, dense=true, icon="more_vert")
                                      ])
        row([
             h1("DancingQueen")
            ])
        row([
             card(class="st-col col-12", 
                  [
                   row([
                        imageview(src=:imageurl, basic=true, style="max-width: $(h)px")
                       ])
                   row([
                        toggle(:recording_label, :recording_on)
                       ])
                  ])
            ])
row([
     h6("Link factor")
     slider(-1:0.1:1, :link_facto, markers=true, labelalways=true)
    ])
row([
     h6("Sun color")
     card(class="st-col col-12",
          [
           row([
                cell(size = 1, span("Red"))
                cell(slider(range(0, 1, 256), :red, markers=true, label=true, color="red"))
               ])
           row([
                cell(size = 1, span("Green"))
                cell(slider(range(0, 1, 256), :green, markers=true, label=true, color="green"))
               ])
           row([
                cell(size = 1, span("Blue"))
                cell(slider(range(0, 1, 256), :blue, markers=true, label=true, color="blue"))
               ])
          ])
    ])
row([
     h6("Sun width")
     slider(1:2:nleds, :sun_widt, markers=true, label=true)
    ])
]

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
