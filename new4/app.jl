module App

using DancingQueen

set_setup, get_image, get_state = main()

using GenieFramework
using JpegTurbo
using ImageCore

@genietools

route("/frame") do
    img = colorview(Gray, normedview(get_image()))
    respond(String(jpeg_encode(img)), :jpg)
end

@app begin
    @out imageurl = "/frame"
    @in setups_labels = [String(rand(UInt8, 5)) for _ in 1:10]
    @in chosen = 0
end

Timer(3600; interval=3600) do _
    if length(Genie.WebChannels.connected_clients()) == 0
        @show "close the camera"
    end
end

ui() = [
        row(heading("DancingQueen"))
        row(imageview(src=:imageurl, basic=true))
        list(bordered = true, separator = true, dense=true, style = "max-width: 96%; width: 96%; margin: 0 auto;", @recur("(label, index) in setups_labels"), [radio("tmp", :chosen, val = :index, label=:label)])
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
@created "setInterval(this.updateimage, 500)"

@page("/", ui)

Server.up(8000, "0.0.0.0")
# Server.up()

end

# using GenieFramework; Genie.loadapp();
