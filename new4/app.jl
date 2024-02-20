module App

using DancingQueen

set_setup, get_image, get_state = main()

using Genie
using GenieFramework
using JpegTurbo
using ImageCore
using TOML, JSONSchema

Genie.config.cdn_enabled = false

@genietools

click() = respond(String(jpeg_encode(colorview(Gray, normedview(get_image())))), :jpg)

payload = Ref(click())
Threads.@spawn while true
    payload[] = click()
    sleep(0.1)
end

const schema = Schema(read("schema.json", String))
const basic_settings = Dict("label" => "Off", "camera" => 2464, "suns" => [Dict("link_factor" => 0)])

get_labels(setups::Vector{<:AbstractDict}) = [string(k, ": ", setup["label"]) for (k, setup) in zip('a':'z', setups)]

route("/frame") do
    payload[]
end

@app begin
    @out imageurl = "/frame"
    @private setups = [basic_settings]

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
                setups = pushfirst!(dict["setups"], basic_settings)
            catch e
                @error "Error processing file: $e"
                notify(__model__,"Error processing file: $(fileuploads["name"])")
            end
            empty!(fileuploads)
            # fileuploads = Dict{AbstractString,AbstractString}()
        end
    end

    @out setups_labels = ["a: Off"]
    @onchange setups begin
        setups_labels = get_labels(setups)
    end
    @in chosen = 0
    @onchange chosen begin
        if chosen < length(setups)
            set_setup(setups[chosen + 1])
        end
    end

end

Timer(3600; interval=3600) do _
    if length(Genie.WebChannels.connected_clients()) == 0
        @info "closing the camera"
        set_setup(Dict("camera" => 0))
    end
end

ui() = [
        row(heading("DancingQueen"))
        row(imageview(src=:imageurl, basic=true))
        row(list(bordered = true, separator = true, dense=true, style = "max-width: 96%; width: 96%; margin: 0 auto;", @recur("(label, index) in setups_labels"), [radio("tmp", :chosen, val = :index, label=:label)]))
        row(uploader(
                     multiple = false,
                     accept = ".toml",
                     autoupload = true,
                     hideuploadbtn = true,
                     label = "Upload setup file",
                     nothumbnails = true,
                     style = "max-width: 100%; width: 100%; margin: 0 auto;",
                     @on("finish", :finished)
                    )
           )
       ]

@methods """updateimage: async function () { this.imageurl = "frame#" + new Date().getTime() }"""
@created "setInterval(this.updateimage, 200)"

@page("/", ui)

Server.up(8000, "0.0.0.0")
# Server.up()

end

# using GenieFramework; Genie.loadapp();
