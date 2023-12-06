struct Camera
    o::Base.Process
    task::Task
    img::SubArray{UInt8, 2, Base.ReshapedArray{UInt8, 2, SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}, Tuple{}}, Tuple{UnitRange{Int64}, UnitRange{Int64}}, false}
    click::Observable{nothing}
    function Camera(w, h, fps)
        buff, img = create_buffer(w, h)
        o, task, click = otask(buff)
        new(o, task, img, click)
    end
end

function otask(buff)
    cmd = `libcamera-vid -n --framerate $fps --width $w --height $h --timeout 0 --codec yuv420 -o -`
    o = open(cmd)
    click = Observable(nothing)
    task = Threads.@spawn while isopen(o)
        read!(o, buff)
        click[] = nothing
        sleep(0.001)
    end
    return o, task, click
end

function create_buffer(w, h)
    w2 = 64ceil(Int, w/64) # dimension adjustments to hardware restrictions
    h2 = 32ceil(Int, h/32)
    nb = Int(w2*h2*3//2) # total number of bytes per frame
    buff = Vector{UInt8}(undef, nb)
    img = Base.view(reshape(Base.view(buff, 1:w2*h2), w2, h2), 1:w, 1:h)
    return (buff, view(img, 1:10, 1:10))
end


