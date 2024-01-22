using Dates
using GLMakie, ImageCore
using HTTP.WebSockets
import ColorTypes: Gray, N0f8
using JSON3

c = Condition()

h = 2464
setup = Observable(Dict("camera" => h, "suns" => [Dict("link_factor" => 0)]))
bts = zeros(UInt8, h*h)

convert2image(bts, h) = colorview(Gray, normedview(reshape(bts, h, h)))
img = Observable(convert2image(bts, h))

fig = Figure()
ax = Axis(fig[1,1], aspect = AxisAspect(1))
on(setup) do _
    h = get(setup[], "camera", 1080)
    bts = zeros(UInt8, h*h)
    img[] = convert2image(bts, h)
    autolimits!(ax)
end
image!(ax, img)
display(fig)

client = @async WebSockets.open("ws://192.168.50.187:8000") do ws
    send(ws, JSON3.write(setup[]))
    for msg in ws
        h = get(setup[], "camera", 1080)
        if sqrt(length(msg)) == h
            img[] = convert2image(msg, h)
        end
        send(ws, JSON3.write(setup[]))
    end
end

# setup[] = Dict("camera" => 480, "suns" => [Dict("link_factor" => 0)])





# h1 = Threads.@spawn while true
#     notify(img)
#     sleep(1/3)
# end

# h = Threads.@spawn WebSockets.open(fun, "ws://192.168.50.187:8000", verbose=true)


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
