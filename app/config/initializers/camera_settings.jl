using StaticArrays, LinearAlgebra

const SV = SVector{2, Float64}
const w = 460#1080
const h = 640#1920

struct Beetle
    c::SV
    u::SV
    Beetle(c::SV, d::SV) = new(c, normalize(d))
end

Beetle() = Beetle(SV(0,0), SV(1,0))

get_θ(b) = atan(b.u[2], b.u[1])

print_row(b) = string(b.c[1], ",", b.c[2], ",", get_θ(b))

