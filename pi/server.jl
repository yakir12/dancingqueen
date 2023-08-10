using HTTP.WebSockets, JSON3, Observables, VideoIO

w, h = (1280, 720)
cam = VideoIO.opencamera(; transcode=false)
buff = Vector{UInt8}(undef, 2w*h)
msg = Observable(buff[1:w*h])
# w, h = size(img[])

@async while isopen(cam)
    read!(cam, buff)
    msg[] = buff[1:2:2w*h]
    sleep(0.0001)
end

server = WebSockets.listen!("127.0.0.1", 8081) do ws
    for _ in ws
        send(ws, msg[])
    end
end

# close(server)
