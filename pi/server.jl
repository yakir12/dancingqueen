using HTTP.WebSockets, ImageCore

function create_buffer(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    h2 = 32ceil(Int, h/32)
    nb = Int(w2*h2*3//2) # total number of bytes per frame
    return (w2, h2, Vector{UInt8}(undef, nb))
end

struct Camera
    o::Base.Process
    buff::Vector{UInt8}
    b
    # img # a reshaped view into the bytes buffer 
    function Camera(w, h, fps)
        w2, h2, buff = create_buffer(w, h)
        b = view(buff, 1:w2*h2)
        # Y = reshape(b, w2, h2)
        # img = colorview(Gray, normedview(view(Y, 1:w, 1:h)))
        cmd = `libcamera-vid -n --framerate $fps --width $w --height $h -t 0 --codec yuv420 -o -` # I imagine that there might be a number of arguments improving things here, or tailoring it to what the user needs/wants
        o = open(cmd) # to "close" the camera just `kill(c.o)`
        new(o, buff, b)
    end
end

function Base.read!(c::Camera)
    read!(c.o, c.buff) # not sure if `readbytes!` might be better here...
    return c.b
end

w, h = (3280, 2464)
cam = Camera(w, h, 10)

server = WebSockets.listen!("127.0.0.1", 8081) do ws
    for _ in ws
        send(ws, read!(cam))
    end
end

# close(server)
