module Track

import ..Beetle, ..Sun

export TrackedSun, update!

mutable struct TrackedBeetle
    previouse_θ::Float64
    Δ::Float64
end

const tb = TrackedBeetle(0, 0)

function track!(tb::TrackedBeetle, beetle::Beetle)
    Δ = beetle.θ - tb.previouse_θ
    Δ += Δ > π ? -2π : Δ < -π ? 2π : 0
    tb.previouse_θ = beetle.θ
    tb.Δ = Δ
    return tb
end

mutable struct TrackedSun
    θ::Float64
    sun::Sun
end

function rotate!(ts::TrackedSun, tb::TrackedBeetle)
    ts.θ += ts.sun.link_factor * tb.Δ
    return ts
end

update!(tsuns, ::Nothing) = tsuns

function update!(tsuns, beetle::Beetle)
    track!(tb, beetle)
    for ts in tsuns
        rotate!(ts, tb)
    end
    return tsuns
end

end
