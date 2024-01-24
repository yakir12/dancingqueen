


module MyServer
using HTTP.WebSockets
using Sockets
import ColorTypes: Gray, N0f8
# using JSON3
#
const fps = 1
const img_height = 100

img = Ref(rand(UInt8, img_height^2))

Threads.@spawn while true
    Threads.@spawn begin
        img[] = rand(UInt8, img_height^2)
    end
    sleep(1/fps)
end

get_image(_) = img[]

cam = 1

# setup, cam, instance = main();

server = WebSockets.listen!("127.0.0.0", 8000) do ws
    Sockets.nagle(ws.io.io, false)
    Sockets.quickack(ws.io.io, true)
    for msg in ws
        send(ws, get_image(cam))
        # if !isempty(msg)
        #     setup[] = JSON3.read(msg, Dict)
        # end
    end
end
end



using HTTP.WebSockets
using Sockets
import ColorTypes: Gray, N0f8
using Dates
using GLMakie, ImageCore
using JSON3

c = Condition()

const img_height = 100

setup = Observable(Dict("camera" => img_height, "suns" => [Dict("link_factor" => 0)]))
bts = zeros(UInt8, img_height*img_height)

convert2image(bts, img_height) = colorview(Gray, normedview(reshape(bts, img_height, img_height)))
img = Observable(convert2image(bts, img_height))

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

const benchmark = Ref(now())

function report_bm()
    t = now()
    Δ = t - benchmark[]
    fps = 1000 ÷ max(1, Dates.value(Δ))
    benchmark[] = t
    println(fps)
end

client = @async WebSockets.open("ws://127.0.0.0:8000") do ws
    # client = @async WebSockets.open("ws://192.168.50.187:8000") do ws
    send(ws, JSON3.write(setup[]))
    for msg in ws
        h = get(setup[], "camera", 1080)
        if sqrt(length(msg)) == img_height
            img[] = convert2image(msg, img_height)
            report_bm()
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
