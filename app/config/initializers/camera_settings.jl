using StaticArrays

const SV = SVector{2, Float64}
const w = 720#480#1080
const h = 1280#640#1920


struct Beetle
    c::SV
    θ::Float64
end

print_row(b) = string(b.c[1], ",", b.c[2], ",", b.θ)

