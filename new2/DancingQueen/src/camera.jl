# struct Camera
#     cam::VideoIO.VideoReader{true, VideoIO.SwsTransform, String}
#     img::PermutedDimsArray{RGB{N0f8}, 2, (2, 1), (2, 1), Matrix{RGB{N0f8}}}
#     w::Int
#     h::Int
#     function Camera(dev)
#         cam = opencamera(dev)
#         img = read(cam)
#         w, h = size(img)
#         new(cam, img, w, h)
#     end
# end
# Base.close(cam::Camera) = close(cam.cam)
# Base.size(cam::Camera) = (cam.w, cam.h)
#
# Base.isopen(cam::Camera) = isopen(cam.cam)
# snap(cam::Camera) = read!(cam.cam, cam.img)

struct Camera
    o::Base.Process
    buff::Vector{UInt8}
    img
    w::Int
    h::Int
    function Camera()
        w, h, fps = (640, 480, 30)
        buff, view2img = create_buffer(w, h)
        cmd = `libcamera-vid -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`
        o = open(cmd)
        new(o, buff, view2img, h, w)
    end
end

function create_buffer(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    h2 = 32ceil(Int, h/32)
    nb = Int(w2*h2*3//2) # total number of bytes per frame
    buff = Vector{UInt8}(undef, nb)
    view2img = colorview(Gray, normedview(Base.view(reshape(Base.view(buff, 1:w2*h2), w2, h2), w:-1:1, 1:h)))
    return (buff, view2img)
end

Base.close(cam::Camera) = close(cam.o)
Base.size(cam::Camera) = (cam.w, cam.h)

Base.isopen(cam::Camera) = isopen(cam.o)
function snap(cam::Camera) 
    read!(cam.o, cam.buff)
    return cam.img
end
