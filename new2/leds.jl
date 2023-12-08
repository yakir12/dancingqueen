struct LEDs{N, M}
    sp::SerialPort
    r::NTuple{N, Int}
    msg::MVector{M, UInt8}
    function LEDs{N, M}(baudrate, suns::SVector{N, Sun}) where {N, M}
        sp = open(first(get_port_list()), baudrate)
        r = ntuple(i -> suns[i].r, N)
        msg = MVector{5N, UInt8}(undef)
        for (i, sun) in zip(1:5:5N, suns)
            msg[i:i + 2] .= tomsg(sun.color)
        end
        new(sp, r, msg::MVector{5N, UInt8})
    end
end
LEDs(baudrate, suns::SVector{N, Sun}) where {N} = LEDs{N, 5N}(baudrate, suns)

function Base.close(leds::LEDs) 
    fill!(leds.msg, 0)
    write(leds.sp, cobs_encode(leds.msg))
    close(leds.sp)
end

tounsigend(x::N0f8) = reinterpret(UInt8, x)

tomsg(c::Color) = [tounsigend(getfield(c, f)) for f in (:r, :g, :b)]

α2index(α) = mod(round(Int, nleds*α/2π), nleds) + 1

function θ2indices(r, θ)
    i = α2index(θ)  
    i1 = mod(i - r - 1, nleds) + 1
    i2 = mod(i + r - 1, nleds) + 1
    return (i1, i2)
end

function (leds::LEDs{N})(sun_θs::MVector{N, Float64}) where {N}
    for (i, r, sun_θ) in zip(1:5:5N, leds.r, sun_θs)
        leds.msg[i + 3:i + 4] .= θ2indices(r, sun_θ)
    end
    Threads.@spawn write(leds.sp, cobs_encode(leds.msg))
end

iterate_leds_indices(leds::LEDs{N}) where {N} = (leds.msg[i + 3:i + 4] for i in 1:5:5N)

iterate_leds_colors(leds::LEDs{N}) where {N} = (RGB{N0f8}(tofixed.(leds.msg[i:i + 2])...) for i in 1:5:5N)

# function get_start_stop(leds::LEDs{N}) where N
#     SVector{N, SVector{2, UInt8}}(leds.msg[i + 3:i + 4] for i in 1:5:5N)
# end
