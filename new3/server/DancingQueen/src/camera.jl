@enum CamMode cmoff=0 cm2464=2464 cm1080=1080 cm1232=1232 cm480=480

camera_settings(cm::CamMode) = cm == cm480 ? (w = 640, h = 480, fps = 206) :
                               cm == cm1232 ? (w = 1640, h = 1232, fps = 83) :
                               cm == cm1080 ? (w = 1920, h = 1080, fps = 47) :
                               cm == cm2464 ? (w = 3280, h = 2464, fps = 21) :
                               (w = 640, h = 480, fps = 0)

function get_buffer_img(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    nb = Int(w2*h*3/2) # total number of bytes per img
    buff = Vector{UInt8}(undef, nb)
    i1 = (w - h) ÷ 2
    i2 = i1 + h - 1
    img = view(reshape(view(buff, 1:w2*h), w2, h), i1:i2, h:-1:1)
    return buff, img
end

struct Camera
    mode::CamMode
    buff::Vector{UInt8}
    img::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    proc::Base.Process
    detector::DetectoRect
    function Camera(cm::CamMode)
        w, h, fps = camera_settings(cm)
        buff, img = get_buffer_img(w, h)
        proc = open(`rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`)
        eof(proc)
        if cm == cmoff
            kill(proc)
        end
        detector = DetectoRect(h, camera_distance, tag_width, widen_radius)
        new(cm, buff, img, proc, detector)
    end
end

function Base.close(cam::Camera) 
    kill(cam.proc)
    close(cam.detector)
end

function detect(cam::Camera) 
    read!(cam.proc, cam.buff)
    cam.detector(cam.img)
end

CamMode(setup::Dict) = CamMode(get(setup, "camera", 1080))

##### the only four options:
# w, h, fps = (3280, 2464, 21) # 
# w, h, fps = (1920, 1080, 47) # same high resolution as 3280
# w, h, fps = (1640, 1232, 83) # same low resolution as 640
# w, h, fps = (640, 480, 206)

get_camera_fov(h::Int) = 
h == 480 ? 480/1232*48.8 :
h == 1232 ? 48.8 :
h == 1080 ? 1080/2464*48.8 :
h == 2464 ? 48.8 :
nothing

# struct Camera
#     cm::CamMode
#     img::Matrix{Float64}
#     Camera(cm::CamMode) = new(cm, zeros(Float64, Int(cm), Int(cm)))
# end
# function snap(cam::Camera) 
#     sleep(1)
#     cam.img .= rand(Float64, Int(cam.cm), Int(cam.cm))
#     return cam.img
# end
#
# function Base.close(cam::Camera) 
#     nothing
# end

###############
# setup[] = Dict("camera" => 2464, "suns" => [Dict("link_factor" => 0)])

