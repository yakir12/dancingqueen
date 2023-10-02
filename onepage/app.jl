include("DancingQueen.jl")

using .DancingQueen

using TOML
using ImageDraw, CoordinateTransformations, Rotations, JpegTurbo, Colors, JSONSchema, JSONSchema
import Colors.N0f8
import DataStructures: OrderedDict

include("display.jl")
include("settings.jl")

using GenieFramework
@genietools

route(get_frame, "/frame")

route(respond ∘ get_recordings, "/data")

const setups = Ref{OrderedDict{String, Vector{Sun}}}()


Genie.config.cors_headers["Access-Control-Allow-Origin"]  =  "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]
route("/settings", method = POST) do
    files = Genie.Requests.filespayload()
    for file in files
        txt = String(last(file).data)
        _setups = try2settings(txt)
        if _setups isa String
            @warn _setups
        else
            setups[] = _setups
            set_suns(first(values(setups[])))
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

    @in chosen = ""

    @onchange chosen begin
        # when keyboard is pressed the key will be wrong
        set_suns(setups[][chosen])
    end

end myhandlers

ui() = Html.div(
                @on("keydown.a", "chosen=\"a\""),
                @on("keydown.b", "chosen=\"b\""),
                @on("keydown.c", "chosen=\"c\""),
                @on("keydown.d", "chosen=\"d\""),
                @on("keydown.e", "chosen=\"e\""),
                @on("keydown.f", "chosen=\"f\""),
                @on("keydown.g", "chosen=\"g\""),
                @on("keydown.h", "chosen=\"h\""),
                @on("keydown.i", "chosen=\"i\""),
                @on("keydown.j", "chosen=\"j\""),
                @on("keydown.k", "chosen=\"k\""),
                @on("keydown.l", "chosen=\"l\""),
                @on("keydown.m", "chosen=\"m\""),
                @on("keydown.n", "chosen=\"n\""),
                @on("keydown.o", "chosen=\"o\""),
                @on("keydown.p", "chosen=\"p\""),
                @on("keydown.q", "chosen=\"q\""),
                @on("keydown.r", "chosen=\"r\""),
                @on("keydown.s", "chosen=\"s\""),
                @on("keydown.t", "chosen=\"t\""),
                @on("keydown.u", "chosen=\"u\""),
                @on("keydown.v", "chosen=\"v\""),
                @on("keydown.w", "chosen=\"w\""),
                @on("keydown.x", "chosen=\"x\""),
                @on("keydown.y", "chosen=\"y\""),
                @on("keydown.z", "chosen=\"z\""),
                [row([
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
                 row([row(radio(msg, :chosen, val = msg)) for msg in ("Off", "One stationary green sun", "Two different suns")])
                ])

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
