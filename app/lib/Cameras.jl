module Cameras

using Dates
using Observables

# const w = 1080
# const h = 1920
const w = 108
const h = 192
const fps = 30

recording = Observable(false)

on(recording) do record
    if record
        @info "recording!"
    else
        @warn "not recording"
    end
end

function __init__()
    # camera[] = Camera(w, h, fps)
    # Timer(revive, 1; interval = 3)
end

struct Camera
    o::Base.Process
    task::Task
    img
    function Camera(w, h, fps)
        buff, img = create_buffer(w, h)
        cmd = `libcamera-vid -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`
        o = open(cmd)
        task = Threads.@spawn while isopen(o)
            read!(o, buff)
            pose = get_pose(buff)
            @info pose
            sleep(0.001)
        end
        new(o, task, img)
    end
end

function create_buffer(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    h2 = 32ceil(Int, h/32)
    nb = Int(w2*h2*3//2) # total number of bytes per frame
    buff = Vector{UInt8}(undef, nb)
    img = Base.view(reshape(Base.view(buff, 1:w2*h2), w2, h2), 1:w, 1:h)
    return (buff, view(img, 1:10, 1:10))
end

const camera = Ref{Camera}()

function revive(timer)
    if !isopen(camera[].o) || istaskfailed(camera[].task)
        close(camera[].o)
        camera[] = Camera(w, h, fps)
    end
end

snap() = rand(UInt8, w, h)
# snap() = camera[].img

get_pose(buff) = (; t = now(), location = rand(), direction = rand())

end
