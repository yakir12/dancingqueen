using StaticArrays

const SV = SVector{2, Float64}
const w = 1080#720#480#
const h = 1920#1280#640#
const nleds = 100


struct Beetle
    c::SV
    θ::Float64
end

print_row(b) = string(b.c[1], ",", b.c[2], ",", b.θ)

