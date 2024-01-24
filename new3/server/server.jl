using Dates
using DancingQueen
using Oxygen
using ImageCore
using JSON3

setup, cam, instance = main();


@get "/frame" function(req::HTTP.Request)
    binary(get_image())
end

server = WebSockets.listen!("0.0.0.0", 8000) do ws
    Sockets.nagle(ws.io.io, false)
    Sockets.quickack(ws.io.io, true)
    for msg in ws
        send(ws, get_image(cam))
        if !isempty(msg)
            setup[] = JSON3.read(msg, Dict)
        end
    end
end

