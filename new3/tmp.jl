using Stipple, Stipple.ReactiveTools
using StippleUI
using StippleDownloads

const asset = rand(UInt8, 10^7) # 10 MB

@app @event download_event download_binary(__model__, asset, "name"; client = event["_client"])

ui() = btn("Download", @on(:click, :download_event, :addclient), loading=:download_event)

@page("/", ui)

up()

