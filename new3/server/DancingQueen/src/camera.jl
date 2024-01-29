struct Camera
    o::Base.Process
    buff::Vector{UInt8}
    img::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    h::Int
    function Camera(h::Int)
        w, h, fps = get_camera_settings(h)
        buff, img = create_buffer(w, h)
        cmd = `rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`
        o = open(cmd)
        new(o, buff, img, h)
    end
end

function create_buffer(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    nb = Int(w2*h*3/2) # total number of bytes per img
    buff = Vector{UInt8}(undef, nb)
    i1 = (w - h) ÷ 2
    i2 = i1 + h - 1
    img = view(reshape(view(buff, 1:w2*h), w2, h), i1:i2, h:-1:1)
    return (buff, img)
end

function Base.close(cam::Camera) 
    close(cam.o)
    wait(cam.o)
end

Base.size(cam::Camera) = (cam.h, cam.h)

Base.isopen(cam::Camera) = isopen(cam.o)

function snap(cam::Camera) 
    read!(cam.o, cam.buff)
    return cam.img
end

##### the only four options:
# w, h, fps = (3280, 2464, 21) # 
# w, h, fps = (1920, 1080, 47) # same high resolution as 3280
# w, h, fps = (1640, 1232, 83) # same low resolution as 640
# w, h, fps = (640, 480, 206)

get_camera_settings(h::Int) = 
h == 480 ? (w = 640, h = 480, fps = 206) :
h == 1232 ? (w = 1640, h = 1232, fps = 83) :
h == 1080 ? (w = 1920, h = 1080, fps = 47) :
h == 2464 ? (w = 3280, h = 2464, fps = 21) :
nothing

get_camera_fov(h::Int) = 
h == 480 ? 480/1232*48.8 :
h == 1232 ? 48.8 :
h == 1080 ? 1080/2464*48.8 :
h == 2464 ? 48.8 :
nothing

