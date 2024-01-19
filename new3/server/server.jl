using Dates
using DancingQueen
using HTTP.WebSockets
using Sockets
using ImageCore

setup, img = main();

server = WebSockets.listen!("0.0.0.0", 8000, verbose=true) do ws
    Sockets.nagle(ws.io.io, false)
    Sockets.quickack(ws.io.io, true)
    for msg in ws
        bts = collect(reshape(rawview(channelview(img[])), :))
        send(ws, bts)
    end
end

