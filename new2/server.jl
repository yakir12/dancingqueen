import TOML, Tar
using DancingQueen
using JSONSchema, JpegTurbo

using GenieFramework
using Stipple, Stipple.ReactiveTools
using StippleUI
using StippleDownloads
import Stipple.opts
@genietools

const schema = Schema(read("schema.json", String))

get_labels(setups::Vector{<:AbstractDict}) = [string(k, ": ", setup["label"]) for (k, setup) in zip('a':'z', setups)]

setup, img = main();

isdir("data") || mkdir("data")

route("/frame") do
    respond(String(jpeg_encode(img[]; transpose = false)), :jpg)
end

Genie.config.cors_headers["Access-Control-Allow-Origin"]  =  "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]
route("/settings", method = POST) do
    caption = "You have to first fix your setting.toml file"
    files = Genie.Requests.filespayload()
    for file in files
        txt = String(last(file).data)
        dict = TOML.tryparse(txt)
        if dict isa Base.TOML.ParserError
            warning = "settings file had bad TOML format"
            @warn warning
            notify(model, warning, :negative; caption)
        else
            msg = validate(schema, dict)
            if isnothing(msg)
                setups = dict["setups"]
                pushfirst!(setups, DancingQueen.off_sun)
                model.setups[] = setups
                notify(model.setups)
            else
                warning = string(replace(string(msg.x), ">" => "&gt;"), " is wrong")
                @warn msg
                notify(model, warning, :negative; caption)
            end
        end
    end
    if length(files) == 0
        @info "No file uploaded"
    end
    return "Upload finished"
end

@app FromFile begin
    @in chosen = 0
    @out downloading = false
    @onchange downloading begin
        chosen = 0 # close the recording
        sleep(1) # wait for the file to close before you start downloading
        downloaddata()
    end
    @out imageurl = "/frame"
    @in setups = [DancingQueen.off_sun]
    @in setups_labels = ["a: Off"]
    @onchange setups begin
        setups_labels = get_labels(setups)
    end
    @onchange chosen begin
        if chosen < length(setups)
            setup[] = setups[chosen + 1]
        end
    end
end myhandlers

function downloaddata()
    @info "pressed download"
    io = IOBuffer()
    try
        Tar.create("data", io)
        download_binary(model, take!(io), string(round(now(), Second(1)), ".tar"))
        @info "download worked, deleting files"
        rm.(readdir("data"; join=true))
    catch ex
        @warn ex
        @warn "download failed, not delteing files"
    end
    close(io)
end

@event FromFile download_data downloaddata()

ui() = Html.div(
                @on("keydown.a", "chosen=0"), @on("keydown.b", "chosen=1"), @on("keydown.c", "chosen=2"), @on("keydown.d", "chosen=3"), @on("keydown.e", "chosen=4"), @on("keydown.f", "chosen=5"), @on("keydown.g", "chosen=6"), @on("keydown.h", "chosen=7"), @on("keydown.i", "chosen=8"), @on("keydown.j", "chosen=9"), @on("keydown.k", "chosen=10"), @on("keydown.l", "chosen=11"), @on("keydown.m", "chosen=12"), @on("keydown.n", "chosen=13"), @on("keydown.o", "chosen=14"), @on("keydown.p", "chosen=15"), @on("keydown.q", "chosen=16"), @on("keydown.r", "chosen=17"), @on("keydown.s", "chosen=18"), @on("keydown.t", "chosen=19"), @on("keydown.u", "chosen=20"), @on("keydown.v", "chosen=21"), @on("keydown.w", "chosen=22"), @on("keydown.x", "chosen=23"), @on("keydown.y", "chosen=24"), @on("keydown.z", "chosen=25"),
                [
                 row([
                      h1("DancingQueen")
                     ])
                 row([
                      card(class="st-col col-12", 
                           [
                            row([
                                 imageview(src=:imageurl, basic=true, style="max-width: 500px")
                                ])
                           ])
                     ])
                 row([
                      uploader(label="Upload settings", multiple=false, accept=".toml", method="POST", url="/settings", hideuploadbtn=true, nothumbnails=true, field__name="csv_file", autoupload=true)
                      btn(class = "q-ml-lg", "Download data", icon = "download", @click(:downloading), color = "primary", nocaps = true, nothumbnails = true, loading = :downloading)
                     ])
                 row([row(@recur("(label, index) in setups_labels"), [radio("tmp", :chosen, val = :index, label=:label)])])
                ])


Stipple.js_methods(model::FromFile) = """updateimage: async function () { this.imageurl = "frame#" + new Date().getTime() }"""

Stipple.js_created(model::FromFile) = "setInterval(this.updateimage, 100)"

route("/") do
    global model = init(FromFile, debounce = 0) |> myhandlers
    page(model, ui) |> html
end

up(8000, "0.0.0.0")

if !isinteractive()
    c = Condition()
    wait(c)
end

