module Cameras

using VideoIO # remove

export Camera, snap!, isopen

# const w = Main.App.camera_settings.w
# const h = Main.App.camera_settings.h
# const fps = 30


# struct Camera
#     o::Base.Process
#     task::Task
#     img
#     logbook::LogBook
#     function Camera(w, h, fps)
#         logbook = LogBook()
#         buff, img = create_buffer(w, h)
#         cmd = `libcamera-vid -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`
#         o, task = otask(buff, img, logbook)
#         new(o, task, img, logbook)
#     end
# end
#
# function otask(cmd, buff, img, logbook)
#     o = open(cmd)
#     task = Threads.@spawn while isopen(o)
#         read!(o, buff)
#         pose = get_pose(img)
#         logbook.recording[] && println(logbook.io[], pose)
#     end
#     return o, task
# end

struct Camera
    o
    buff
    function Camera()
        o = opencamera()
        buff = read(o)
        new(o, buff)
    end
end

# function create_buffer(w, h)
#     w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
#     h2 = 32ceil(Int, h/32)
#     nb = Int(w2*h2*3//2) # total number of bytes per frame
#     buff = Vector{UInt8}(undef, nb)
#     img = Base.view(reshape(Base.view(buff, 1:w2*h2), w2, h2), 1:w, 1:h)
#     return (buff, view(img, 1:10, 1:10))
# end

Base.isopen(cam::Camera) = isopen(cam.o)
snap!(cam) = read!(cam.o, cam.buff)

end
