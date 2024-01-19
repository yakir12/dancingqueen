using Dates
using GLMakie, ImageCore
using HTTP.WebSockets
import ColorTypes: RGB, N0f8

w = 300
_img = ones(RGB{N0f8}, w, w)
const bts = reshape(rawview(channelview(_img)), :)

function fun(ws)
    send(ws, "hello")
    for msg in ws
        bts .= msg
        send(ws, "again")
    end
end



# y = Observable(rand(0:255, 5))

fig = Figure()
ax = Axis(fig[1,1], aspect = AxisAspect(1), yreversed=true)
img = Observable(_img)
image!(ax, img)
display(fig)

h1 = Threads.@spawn while true
    notify(img)
    sleep(1/3)
end

h = Threads.@spawn WebSockets.open(fun, "ws://192.168.50.187:8000", verbose=true)


# using GLMakie
# using ImageCore
# using HTTP.WebSockets
# using Sockets
#
# w = 100
#
# server = WebSockets.listen!("127.0.0.0", 8000) do ws
#     Sockets.nagle(ws.io.io, false)
#     Sockets.quickack(ws.io.io, true)
#     for _ in ws
#         msg = rand(UInt8, 3w*w)
#         send(ws, msg)
#     end
# end
#
# img = Observable(ones(RGB{N0f8}, w, w))
# image(img)
# bts = reshape(rawview(channelview(img[])), :)
#
# client = @async WebSockets.open("ws://127.0.0.0:8000") do ws
#     send(ws, "ready")
#     for msg in ws
#         bts .= msg
#         notify(img)
#         send(ws, "one more")
#     end
# end
#
