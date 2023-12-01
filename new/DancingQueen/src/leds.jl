struct LEDSun
    i1::Int
    i2::Int
    color::Color
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

middle(ls::LEDSun) = mod((ls.i1 + ls.i2) ÷ 2 - 1, nleds) + 1

α2index(α) = mod(round(Int, nleds*α/2π), nleds) + 1

function LEDSun(sun::Sun)
    i = α2index(sun.θ)  
    LEDSun(i - sun.r, i + sun.r, sun.color)
end
