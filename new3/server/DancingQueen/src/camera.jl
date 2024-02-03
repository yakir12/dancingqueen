function create_buffer(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    nb = Int(w2*h*3/2) # total number of bytes per img
    return (Vector{UInt8}(undef, nb), w2)
end

function get_frame(buff::Vector{UInt8}, w, h, w2)
    i1 = (w - h) ÷ 2
    i2 = i1 + h - 1
    view(reshape(view(buff, 1:w2*h), w2, h), i1:i2, h:-1:1)
end

mutable struct Camera
    mode::CamMoode
    w::Int
    h::Int
    w2::Int
    buff::Vector{UInt8}
    o::Base.Process

    function Camera()
        w, h, fps = camera_settings(cm480)
        w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
        nb = Int(w2*h*3/2) # total number of bytes per img
        buff =  Vector{UInt8}(undef, nb)
        cmd = `rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`
        o = open(cmd)
        new{h}(o, buff, img)
    end

end

function switch_camera(cm::CamMoode)
    if isstarted(camera)
        if camera.mode == cm
            return nothing
        else
            stop(camera)
        end
    end
    start(cm)
end




abstract type CamMode end

struct CMOFF <: CamMode end
struct CM2464 <: CamMode end
struct CM1080 <: CamMode end



function CamMode(h::Int)
    if h == 2464
        w = 3280, h = 2464, fps = 21



switch2camera(cam1::Camera{T}, cam2::Camera{T}) = cam1

function switch2camera(cam1::Camera{T}, cam2::Camera{R})
    close(cam1)
    open(cam2)
    return cam2
end

open(::CMOFF) = nothing


@enum CamMode cm2464=2464 cm1080=1080 cm1232=1232 cm480=480

struct Camera
    cm::CamMode
    buff::Vector{UInt8}
    img::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
end

function switch2camera(cam::Camera{})
    oO



    if !isopen(camera_process[])
        isopen
    end



function open_camera(cam::Camera, camera_process::Ref{Camera})
        close(camera_process[])
        wait(camera_process[])
    end
    camera_process[] = open(cmd(cam.cm))
end

const camera_settings = Dict{CamMode, @NamedTuple{w::Int64, h::Int64, fps::Int64}}(cm480 => (w = 640, h = 480, fps = 206), cm1232 => (w = 1640, h = 1232, fps = 83), cm1080 => (w = 1920, h = 1080, fps = 47), cm2464 => (w = 3280, h = 2464, fps = 21))

cmd(fps, w, h) = `rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`

struct Camera{H}
    o::Base.Process
    buff::Vector{UInt8}
    img::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, StepRange{Int64, Int64}}, false}
    function Camera(cm::CamMode)
        w, h, fps = camera_settings[cm]
        buff, img = create_buffer(w, h)
        cmd = `rpicam-vid --denoise cdn_off -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`
        o = open(cmd)
        new{h}(o, buff, img)
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
    if isopen(cam)
        close(cam.o)
        wait(cam.o)
    end
end

Base.size(cam::Camera{H}) where {H}= (H, H)

Base.isopen(cam::Camera) = isopen(cam.o)

function snap(cam::Camera) 
    read!(cam.o, cam.buff)
    return cam.img
end

CamMode(d::Dict) = CamMode(get(d, "camera", 1080))

Camera(d::Dict) = Camera(CamMode(d))

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

function update(cam::Camera{H}, cm::CamMode) where H
    if H ≠ Int(cm)
        close(cam)
        Camera(cm)
    else
        cam
    end
end

update(cam::Camera, d::Dict) = update(cam, CamMode(d))
