module LEDs

using CoordinateTransformations, Rotations, AngleBetweenVectors

import Main: SV, Beetle

export get_led

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

function get_ideal_led(b, bearing)
    rot = LinearMap(Angle2d(bearing))
    u = rot(b.u)
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

function get_new_led(old_led, old_beetle, new_beetle, bearing, a)
    p1 = get_ideal_led(old_beetle, bearing)
    p2 = get_ideal_led(new_beetle, bearing)
    if isnothing(p1) || isnothing(p2)
        return old_led
    end
    Δ = angle_between(p2, p1)
    rot = LinearMap(Angle2d(a*Δ))
    return rot(old_led)
end

const old_beetle = Ref(Beetle())
const old_led = Ref(SV(1,0))

function get_led(beetle, bearing, a)
    led = get_new_led(old_led[], old_beetle[], beetle, bearing, a)
    old_beetle[] = beetle
    old_led[] = led
    return led
end

end
