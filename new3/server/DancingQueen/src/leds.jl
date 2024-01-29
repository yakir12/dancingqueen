struct LEDs{N, M}
    sp::SerialPort
    r::NTuple{N, Int}
    msg::MVector{M, UInt8}
    l::ReentrantLock
    function LEDs{N, M}(baudrate, suns::NTuple{N, Sun}) where {N, M}
        sp = open(last(get_port_list()), baudrate)
        r = ntuple(i -> (suns[i].width - 1)/2, N)
        msg = MVector{5N, UInt8}(undef)
        for (i, sun) in zip(1:5:5N, suns)
            msg[i:i + 2] .= sun.color
        end
        new(sp, r, msg, ReentrantLock())
    end
end
LEDs(baudrate, suns::NTuple{N, Sun}) where {N} = LEDs{N, 5N}(baudrate, suns)

function Base.close(leds::LEDs) 
    fill!(leds.msg, 0)
    write(leds.sp, cobs_encode(leds.msg))
    close(leds.sp)
end

α2index(α) = mod(round(Int, nleds*α/2π), nleds) + 1

function θ2indices(r, theta)
    i = α2index(theta)  
    i1 = mod(i - r - 1, nleds) + 1
    i2 = mod(i + r - 1, nleds) + 1
    return (i1, i2)
end

function (leds::LEDs{N})(sun_θs::MVector{N, Float64}) where N
    for (i, r, sun_θ) in zip(1:5:5N, leds.r, sun_θs)
        leds.msg[i + 3:i + 4] .= θ2indices(r, sun_θ - π/2) # -90° cause the LED ring zero is pointing to the West
    end
    # Threads.@spawn 
    @lock leds.l write(leds.sp, cobs_encode(leds.msg))
end

# iterate_leds_indices(leds::LEDs{N}) where {N} = (leds.msg[i + 3:i + 4] for i in 1:5:5N)

