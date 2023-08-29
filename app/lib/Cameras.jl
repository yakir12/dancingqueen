module Cameras

using Dates, LinearAlgebra
using Observables, AprilTags, StaticArrays
using VideoIO # remove

# Base.include(Cameras, "detection.jl")
# Base.include(Cameras, "logging.jl")
include("detection.jl")
include("logging.jl")

# const w = 1080
# const h = 1920
const w = 480
const h = 640
const fps = 30

function __init__()
    camera[] = Camera(w, h, fps)
    Timer(revive, 1; interval = 3)
end

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
    cam
    task::Task
    img
    logbook::LogBook
    function Camera(w, h, fps)
        detector = AprilTagDetector()
        rect = Rect()
        logbook = LogBook()
        cam = opencamera()
        buff = read(cam)
        img = Ref(@view buff[rect.i1:rect.i2, rect.j1:rect.j2])
        task = Threads.@spawn while isopen(cam)
            read!(cam, buff)
            rect = oneiter(detector, buff, img, rect)
            logbook.recording[] && println(logbook.io[], rect)
        end
        new(cam, task, img, logbook)
    end
end

const camera = Ref{Camera}()

function create_buffer(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    h2 = 32ceil(Int, h/32)
    nb = Int(w2*h2*3//2) # total number of bytes per frame
    buff = Vector{UInt8}(undef, nb)
    img = Base.view(reshape(Base.view(buff, 1:w2*h2), w2, h2), 1:w, 1:h)
    return (buff, view(img, 1:10, 1:10))
end


function revive(timer)
    if istaskfailed(camera[].task)
        # if !isopen(camera[].o) || istaskfailed(camera[].task)
        exception = current_exceptions(camera[].task)
        @warn "the camera died for some reason!" exception
        # close(camera[].o)
        # camera[] = Camera(w, h, fps)
    end
end

last_frame() = camera[].img[]

end
