using GLMakie, HTTP.WebSockets

function modified_size(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    h2 = 32ceil(Int, h/32)
    return (w2, h2)
end

w, h = (3280, 2464)
img = Observable(Matrix{UInt8}(undef, w, h))

fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect(), yreversed=true)
image!(ax, img)

w2, h2 = modified_size(w, h)
WebSockets.open("ws://192.168.80.2:8081") do ws
    i = 0
    send(ws, "a")
    for msg in ws
        Y = reshape(msg, w2, h2)
        img[] = view(Y, 1:w, 1:h)
        send(ws, "a")
        i += 1
        if i > 300
            break
        end
    end
end

