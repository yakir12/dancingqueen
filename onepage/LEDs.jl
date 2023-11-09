module LEDs

using Colors
import Colors.N0f8
using ..Track

export LEDStrip

import ..nleds

struct LEDStrip
    i1::Int
    i2::Int
    color::RGB{N0f8}
end

α2index(α) = round(Int, nleds*α/2π + 0.5)

function LEDStrip(ts::TrackedSun)
    i1 = α2index(mod(ts.θ - ts.sun.δ, 2π))
    i2 = α2index(mod(ts.θ + ts.sun.δ, 2π))
    LEDStrip(i1, i2, ts.sun.color)
end

end