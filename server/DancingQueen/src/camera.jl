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
        detector = DetectoRect(cm)
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

