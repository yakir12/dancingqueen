module LEDs

using LinearAlgebra
using CoordinateTransformations, Rotations, AngleBetweenVectors, Observables, StaticArrays

import Main: SV, Beetle, unitize

# TODO: test to see if bearing actually has any effect or not, I think not
# add the offset b in a*Δ + b

export get_led

const bearing = Observable(0.0)
const ideal_rotation = map(LinearMap ∘ Angle2d ∘ deg2rad, bearing)
const link_factor = Ref(0.0)
const old_beetle = Ref(Beetle())
const old_led = Ref(SV(1,0))

function distance(orig, dir)
    b = -orig⋅dir
    disc = b^2 - orig⋅orig + 1
    if disc ≥ 0
        d = sqrt(disc)
        t2 = b + d
        if t2 ≥ 0
            t1 = b - d
            return t1 > 0 ? t1 : t2
        end
    end
    return nothing
end

function get_ideal_led(b)
    u = ideal_rotation[](b.u)
    l = distance(b.c, u)
    if isnothing(l)
        return nothing
    end
    b.c + l*u
end

function angle_between(oldu, newu)
    x1, y1 = oldu
    x2, y2 = newu
    sign((x2 - x1)*(y2 + y1))*angle(oldu, newu)
end

function get_new_led(old_led, old_beetle, new_beetle)
    p1 = get_ideal_led(old_beetle)
    p2 = get_ideal_led(new_beetle)
    if isnothing(p1) || isnothing(p2)
        return old_led
    end
    Δ = angle_between(p2, p1)
    rot = LinearMap(Angle2d(link_factor[]*Δ))
    return rot(old_led)
end

get_led(::Nothing) = old_led[]

function get_led(beetle)
    ub = unitize(beetle)
    led = get_new_led(old_led[], old_beetle[], ub)
    old_beetle[] = ub
    old_led[] = led
    return led
end

end
