include("DancingQueen.jl")

using .DancingQueen

const img = DancingQueen.img
const beetle = DancingQueen.beetle
const tsuns = DancingQueen.tsuns

using ImageDraw, CoordinateTransformations, Rotations, JpegTurbo, Colors, JSONSchema
import Colors.N0f8

using GenieFramework
@genietools

include("leds.jl")
include("display.jl")

route(get_frame, "/frame")

route(respond ∘ get_recordings, "/data")

@app FromFile begin
    @out imageurl = "/frame"

    @in recording_on = false
    @out recording_label = "Not recording"
    @onchange recording_on begin
        toggle_recording(recording_on)
        recording_label = recording_on ? "Recording" : "Not recording"
    end
end myhandlers

ui() = [
        row([
             btn(class = "q-mt-lg", "Download data", color = "primary", href="data", download=string(round(now(), Second(1)), ".tar"))
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
       ]

model = init(FromFile, debounce = 0) |> myhandlers

Stipple.js_methods(model::FromFile) = """
    updateimage: async function () { 
        this.imageurl = "frame#" + new Date().getTime()
    }
"""

# Stipple.js_created(model::FromFile) = """
#     setInterval(() => {
#     this.updateimage();
#     }, 33);
# """

# Stipple.js_created(model::FromFile) = """
# (function loop() {
#   setTimeout(() => {
#     () => this.updateimage;
#     loop();
#   }, 100);
# })();
# """

Stipple.js_created(model::FromFile) = "setInterval(this.updateimage, 101)"# $(round(Int, 5*1000/fps)))"

route("/") do
    global model
    page(model, ui) |> html
end

up()
