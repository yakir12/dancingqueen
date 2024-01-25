using Dates
using GLMakie, ImageCore
using HTTP
import ColorTypes: Gray, N0f8
using JSON3

convert2image(bts, h) = colorview(Gray, normedview(reshape(bts, h, h)))

h = 2464
buff = Vector{UInt8}(undef, h, h)
img = Observable(convert2image(buff, h))

image(img)


function update_img!(buff, img)
    HTTP.open("GET", "http://192.168.50.187:8000/frame") do io
        while !eof(io)
            read!(io, buff)
        end
        notify(img)
    end
end

fps = 25

@async while true
    h = @async update_img!(buff, img)
    t = Timer(1/fps)
    wait(t)
    fetch(h)
end



n = 1000
t = @elapsed begin
    for i in 1:n
        r = HTTP.request("GET", "http://192.168.50.187:8000/state")
        a = JSON3.read(String(r.body))
    end
end
fps = n/t







c = Condition()

h = 2464
setup = Observable(Dict("camera" => h, "suns" => [Dict("link_factor" => 0)]))
bts = zeros(UInt8, h*h)

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
        if sqrt(length(msg)) == h
            img[] = convert2image(msg, h)
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
