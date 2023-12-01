using DancingQueen
using JSONSchema, JpegTurbo
using GenieFramework
import TOML, Tar
@genietools

const prefs = TOML.parsefile("preferences.toml")
const client_fps =  prefs["client"]["fps"]

const schema = Schema(read("schema.json", String))

get_labels(dict) = [string(k, ": ", setup["label"]) for (k, setup) in zip('a':'z', dict["setups"])]

task, setups_dict, chosen_setup, get_frame = start()

# include("settings.jl")

isdir("data") || mkdir("data")

route("/frame") do
    respond(String(jpeg_encode(get_frame())), :jpg)
end

route("/data") do
    io = IOBuffer()
    Tar.create("data", io)
    msg = String(take!(io))
    close(io)
    return respond(msg)
end


Genie.config.cors_headers["Access-Control-Allow-Origin"]  =  "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]
route("/settings", method = POST) do
    files = Genie.Requests.filespayload()
    for file in files
        txt = String(last(file).data)
        dict = TOML.parse(txt)
        msg = validate(schema, dict)
        if msg isa JSONSchema.SingleIssue
            io = IOBuffer()
            show(io, msg)
            msg = string("<p>", replace(strip(String(take!(io))), "\n" => "</p><p>"), "</p>")
            notify(model, msg, :negative, caption = "You have to first fix your setting.toml file", html=true)
        else
            pushfirst!(dict["setups"], Dict("label" => "Off", "suns" => [Dict("link_factor" => 0)]))
            setups_dict[] = dict
            model.setups_labels[] = get_labels(dict)
        end
    end
    if length(files) == 0
        @info "No file uploaded"
    end
    return "Upload finished"
end


@app FromFile begin
    @out imageurl = "/frame"
    @in setups_labels = get_labels(setups_dict[])
    @in chosen = 0
    @onchange chosen chosen_setup[] = chosen + 1
end myhandlers

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
                                 imageview(src=:imageurl, basic=true, style="max-width: $(DancingQueen.h)px")
                                ])
                           ])
                     ])
                 row([
                      uploader(label="Upload settings", multiple=false, accept=".toml", method="POST", url="/settings", hideuploadbtn=false, nothumbnails=true, field__name="csv_file", autoupload=true)
                      btn(class = "q-mt-lg", "Download data", color = "primary", href="data", download=string(round(now(), Second(1)), ".tar"))
                     ])
                 row([row(@recur("(label, index) in setups_labels"), [radio("tmp", :chosen, val = :index, label=:label)])])
                ])

global model = init(FromFile, debounce = 0) |> myhandlers

Stipple.js_methods(model::FromFile) = """updateimage: async function () { this.imageurl = "frame#" + new Date().getTime() }"""

Stipple.js_created(model::FromFile) = "setInterval(this.updateimage, $(1000 ÷ client_fps))"

route("/") do
    # global model
    page(model, ui) |> html
end

up()

if !isinteractive()
    c = Condition()
    wait(c)
end
