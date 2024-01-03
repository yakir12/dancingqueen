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

##### the only four options:
# w, h, fps = (3280, 2464, 21) # 
# w, h, fps = (1920, 1080, 47) # same high resolution as 3280
# w, h, fps = (1640, 1232, 83) # same low resolution as 640
# w, h, fps = (640, 480, 206)

const camera_settings = Dict(480 => (w = 640, h = 480, fps = 206),
                             1232 => (w = 1640, h = 1232, fps = 83),
                             1080 => (w = 1920, h = 1080, fps = 47),
                             2464 => (w = 3280, h = 2464, fps = 21)
                            )

const camera_fov = Dict(480 => 480/1232*48.8,
                        1232 => 48.8,
                        1080 => 1080/2464*48.8,
                        2464 => 48.8
                       )

struct Camera
    o::Base.Process
    buff::Vector{UInt8}
    img
    w::Int
    h::Int
    function Camera(h)
        w, h, fps = camera_settings[h]
        buff, view2img = create_buffer(w, h)
        cmd = `rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`
        o = open(cmd)
        new(o, buff, view2img, w, h)
    end
end

function create_buffer(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    nb = Int(w2*h*3/2) # total number of bytes per frame
    buff = Vector{UInt8}(undef, nb)
    i1 = (w - h) ÷ 2
    i2 = i1 + h - 1
    frame = view(reshape(view(buff, 1:w2*h), w2, h), i2:-1:i1, 1:h)
    view2img = colorview(Gray, normedview(frame))
    return (buff, view2img)
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
