using StaticArrays

const SV = SVector{2, Float64}
const w = 480#1080#720##
const h = 640#1920#1280##
const nleds = 100


struct Beetle
    c::SV
    θ::Float64
end

print_row(b) = string(b.c[1], ",", b.c[2], ",", b.θ)

