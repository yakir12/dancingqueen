using GLMakie, HTTP.WebSockets, JSON3

w, h = (1280, 720)
img = Observable(Matrix{UInt8}(undef, w, h))

fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect(), yreversed=true)
image!(ax, img)

WebSockets.open("ws://127.0.0.1:8081") do ws
    i = 0
    send(ws, "a")
    for msg in ws
        img[] = reshape(msg, w, h)
        send(ws, "a")
        i += 1
        if i > 300
            break
        end
    end
end

