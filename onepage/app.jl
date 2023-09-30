include("DancingQueen.jl")

using .DancingQueen

using TOML
using ImageDraw, CoordinateTransformations, Rotations, JpegTurbo, Colors, JSONSchema, JSONSchema
import Colors.N0f8

include("display.jl")
include("settings.jl")

using GenieFramework
@genietools

route(get_frame, "/frame")

route(respond ∘ get_recordings, "/data")



Genie.config.cors_headers["Access-Control-Allow-Origin"]  =  "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]
route("/settings", method = POST) do
    files = Genie.Requests.filespayload()
    for file in files
        txt = String(last(file).data)
        setups = try2settings(txt)
        if setups isa String
            @warn setups
        else
            set_suns(setups[end].suns)
        end
    end
    if length(files) == 0
        @info "No file uploaded"
    end
    return "Upload finished"
end

@app FromFile begin
    @out imageurl = "/frame"

    @in recording_on = false
    @out recording_label = "Not recording"
    @onchange recording_on begin
        set_recording(recording_on)
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
        row([
             uploader(label="Upload settings", multiple=false, accept=".toml", method="POST", url="/settings", hideuploadbtn=false, nothumbnails=true, field__name="csv_file", autoupload=true)
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
