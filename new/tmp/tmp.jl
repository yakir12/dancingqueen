using Stipple, Stipple.ReactiveTools
using StippleUI
using StippleDownloads

@app MyModel begin
    @event download_event download_binary(model, rand(UInt8, 1), "name")
end myhandlers

global model = init(MyModel, debounce = 0) |> myhandlers

ui() = btn("Download", @on(:click, :download_event))

route("/") do
    page(model, ui) |> html
end

up()
