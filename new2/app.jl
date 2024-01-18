module App

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

@app begin
    @private imageurl = "/frame"
    @private setups = [DancingQueen.off_sun]
    @onchange fileuploads begin
        if !isempty(fileuploads)
            @info "File was uploaded: " fileuploads
            try
                txt = read(fileuploads["path"], String)
                if isempty(txt)
                    warning = "settings file was empty"
                    @warn warning
                    notify(__model__, warning)
                end
                dict = TOML.tryparse(txt)
                if dict isa Base.TOML.ParserError
                    warning = "settings file had bad TOML format"
                    @warn warning
                    notify(__model__, warning)
                end
                error_msg = validate(schema, dict)
                if !isnothing(error_msg)
                    warning = string(replace(string(error_msg.x), ">" => "&gt;"), " is wrong")
                    @warn error_msg
                    notify(__model__, warning)
                end
                setups = pushfirst!(dict["setups"], DancingQueen.off_sun)
            catch e
                @error "Error processing file: $e"
                notify(__model__,"Error processing file: $(fileuploads["name"])")
            end
            empty!(fileuploads)
            # fileuploads = Dict{AbstractString,AbstractString}()
        end
    end
    @event uploaded begin
        @info "uploaded"
        notify(__model__, "File was uploaded")
    end
    @event rejected begin
        @info "rejected"
        notify(__model__, "Please upload a valid file")
    end
    @out setups_labels = ["a: Off"]
    @onchange setups begin
        setups_labels = get_labels(setups)
    end
    @in chosen = 0
    @onchange chosen begin
        if chosen < length(setups)
            setup[] = setups[chosen + 1]
        end
    end
    @event download_event begin
        chosen = 0 # close the recording
        sleep(1) # wait for the file to close before you start downloading
        @info "pressed download"
        io = IOBuffer()
        try
            Tar.create("data", io)
            download_binary(__model__, take!(io), string(round(now(), Second(1)), ".tar"); client = event["_client"])
            @info "download worked, deleting files"
            rm.(readdir("data"; join=true))
        catch ex
            @warn ex
            @warn "download failed, not delteing files"
        end
        close(io)
    end
end

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
                      uploader(label="Upload settings", multiple=false, accept=".toml", hideuploadbtn=true, nothumbnails=true, autoupload=true, @on("rejected", :rejected), @on("uploaded", :uploaded))
                      btn(class = "q-ml-lg", "Download data", icon = "download", @on(:click, :download_event, :addclient), color = "primary", nocaps = true, nothumbnails = true)
                     ])
                 row([row(@recur("(label, index) in setups_labels"), [radio("tmp", :chosen, val = :index, label=:label)])])
                ])

@methods """updateimage: async function () { this.imageurl = "frame#" + new Date().getTime() }"""
@created "setInterval(this.updateimage, 100)"

@page("/", ui)

# up(8000, "0.0.0.0")

# if !isinteractive()
#     c = Condition()
#     wait(c)
# end

end
