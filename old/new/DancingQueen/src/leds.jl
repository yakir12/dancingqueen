struct LEDSun
    i1::Int
    i2::Int
    color::Color
    msg::NTuple{5, UInt8}
    function LEDSun(i1, i2, color)
        msg = (reinterpret(UInt8, color.r), reinterpret(UInt8, color.g), reinterpret(UInt8, color.b), mod(i1 - 1, nleds) + 1, mod(i2 - 1, nleds) + 1)
        new(i1, i2, color, msg)
    end
end

function Base.iterate(ls::LEDSun, i::Int=ls.i1)
    if i > ls.i2
        nothing
    else
        (mod(i - 1, nleds) + 1, i + 1)
    end
end

Base.length(ls::LEDSun) = ls.i2 - ls.i1 + 1

Base.eltype(::Type{LEDSun}) = Int

# function Base.getindex(ls::LEDSun, i::Int)
#     ls.i1 ≤ i ≤ ls.i2 || throw(BoundsError(ls, i))
#     return mod(i - 1, nleds) + 1
# end
#
# Base.firstindex(ls::LEDSun) = ls.i1
#
# Base.lastindex(ls::LEDSun) = mod(ls.i2 - 1, nleds) + 1

middle(ls::LEDSun) = mod((ls.i1 + ls.i2) ÷ 2 - 1, nleds) + 1

α2index(α) = mod(round(Int, nleds*α/2π), nleds) + 1

function LEDSun(sun::Sun)
    i = α2index(sun.θ)  
    LEDSun(i - sun.r, i + sun.r, sun.color)
end

function writeLEDs(leds::Vector{LEDSun}) 
    msg = Vector{UInt8}(undef, 5*length(leds))
    for (i, led) in enumerate(leds)
        msg[(i - 1)*5 + 1:5i] .= led.msg
    end
    encoded = cobs_encode(msg)
    write(serialport[], encoded)
end



# good_port(port) = try
#   sp = open(port, baudrate)
#   sleep(0.1)
#   good = occursin(r"FIBOCOM"i, LibSerialPort.sp_get_port_usb_manufacturer(sp))
#   close(sp)
#   return good
# catch ex
#   return false
# end
#
# function get_port()
#   ports = get_port_list()
#   i = findfirst(good_port, ports)
#   isnothing(i) && throw("No LED strip found")
#   ports[i]
# end
