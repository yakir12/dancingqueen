# TODO:
# case insensitive for the keyboard control
#
import Tar, TOML
using Dates
using VideoIO, AprilTags, StaticArrays, ImageDraw, CoordinateTransformations, Rotations, JpegTurbo, Colors, JSONSchema
import Colors.N0f8

if !isdir("data")
    mkdir("data")
end

const cam = opencamera()
const img = Ref(read(cam))
const w, h = size(img[])
const nleds = 101

include("settings.jl")
include("detection.jl")
include("leds.jl")
include("logbooks.jl")
include("display.jl")

const beetle = Ref{Union{Nothing, Beetle}}(nothing)
const suns = Sun[]
const leds = Ref(LEDs[])

dr = DetectoRect()
logbook = LogBook()

task = Threads.@spawn while isopen(cam)
    read!(cam, img[]) # 1/FPS second
    beetle[] = dr(img[]) # 137 μs to 16 ms when naive
    leds[] = LEDs.(beetle, suns) # 36 ns
    Threads.@spawn log!(logbook, beetle[], leds[]) # sync time 24 ns
end

# ### benchmarks
# function one_round()
#     read!(cam, img[]) # 1/FPS second
#     beetle[] = dr(img[]) # 137 μs to 16 ms when naive
#     leds[] = get_leds(beetle[]) # 36 ns
#     Threads.@spawn log!(logbook, beetle[], leds[]) # sync time 24 ns
# end
# @benchmark one_round() # 100 ms limited by the 10 FPS...
# @benchmark one_round() # 100 ms when naive
#
#
# for i in 1:50
#     read!(cam, img[]) # 1/FPS second
# end
#
# function one_round(img)
#     beetle[] = dr(img[]) # 137 μs to 16 ms when naive
#     leds[] = get_leds(beetle[]) # 36 ns
#     Threads.@spawn log!(logbook, beetle[], leds[]) # sync time 24 ns
# end
# @benchmark one_round(img) # 193 μs
# @benchmark one_round(img) # 16 ms when naive

using GenieFramework
@genietools

# avoid writing to disk
route(get_frame, "/frame")

route("/data") do
    get_data(logbook)
end

@app FromFile begin
    @out imageurl = "/frame"

    @in recording_on = false
    @out recording_label = "Not recording"
    @onchange recording_on begin
        turn!(logbook, recording_on)
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
