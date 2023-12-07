struct Camera
    o::Base.Process
    task::Task
    img::Observable{Base.ReinterpretArray{Gray{N0f8}, 2, N0f8, ImageCore.MappedArrays.MappedArray{N0f8, 2, SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, UnitRange{Int64}}, false}, ImageCore.var"#39#40"{N0f8}, typeof(reinterpret)}, true}}
    function Camera(w, h, fps)
        buff, view2img = create_buffer(w, h)
        o, task, img = otask(buff, view2img)
        new(o, task, img)
    end
end

function otask(buff, view2img)
    cmd = `libcamera-vid -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`
    o = open(cmd)
    img = Observable(view2img)
    task = Threads.@spawn while isopen(o)
        read!(o, buff)
        img[] = view2img
        sleep(0.001)
    end
    return o, task, img
end

function create_buffer(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    h2 = 32ceil(Int, h/32)
    nb = Int(w2*h2*3//2) # total number of bytes per frame
    buff = Vector{UInt8}(undef, nb)
    view2img = colorview(Gray, normedview(Base.view(reshape(Base.view(buff, 1:w2*h2), w2, h2), 1:w, 1:h)))
    return (buff, view2img)
end


