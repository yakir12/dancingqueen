struct Camera
    cam::VideoIO.VideoReader{true, VideoIO.SwsTransform, String}
    img::PermutedDimsArray{RGB{N0f8}, 2, (2, 1), (2, 1), Matrix{RGB{N0f8}}}
    w::Int
    h::Int
    function Camera(dev)
        cam = opencamera(dev)
        img = read(cam)
        w, h = size(img)
        new(cam, img, w, h)
    end
end
Base.close(cam::Camera) = close(cam.cam)
Base.size(cam::Camera) = (cam.w, cam.h)

Base.isopen(cam::Camera) = isopen(cam.cam)
snap(cam::Camera) = read!(cam.cam, cam.img)

