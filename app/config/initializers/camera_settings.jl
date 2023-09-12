using LinearAlgebra
using CoordinateTransformations, StaticArrays

const SV = SVector{2, Float64}
const w = 480#1080
const h = 640#1920
const ring_radius = w/2.1 # in pixels
offset = SV(w/2, h/2) # the offset between the origo of the image pixel coordinates and the center of the LED ring
const to_unit = LinearMap(Diagonal(SVector(1/ring_radius, 1/ring_radius))) ∘ Translation(-offset)


struct Beetle
    c::SV
    u::SV
    Beetle(c::SV, d::SV) = new(c, normalize(d))
end

unitize(b::Beetle) = Beetle(to_unit(b.c), b.u)

Beetle() = Beetle(SV(0,0), SV(1,0))

get_θ(b) = atan(b.u[2], b.u[1])

print_row(b) = string(b.c[1], ",", b.c[2], ",", get_θ(b))

