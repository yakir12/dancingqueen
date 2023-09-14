module Monitor
# TODO 
# should all these global states exist inside each module, or is it better to keep that here?

using .Main.Cameras
using .Main.Detection
using .Main.LogBooks
using .Main.LEDs

import Main.Beetle

export turn_recording!, read_state

function revive(task)
    if istaskfailed(task)
        exception = current_exceptions(task)
        @warn "the camera died for some reason!" exception
    end
end

mutable struct State
    img
    beetle::Union{Nothing, Beetle}
    led::Float64
end

logbook = LogBook()
camera = Camera()
dr = DetectoRect()

const state = State(snap!(camera), nothing, 0.0)

task = Threads.@spawn while isopen(camera)
    state.img = snap!(camera)
    state.beetle = dr(state.img)
    state.led = get_led(state.beetle)
    log!(logbook, state.beetle, state.led)
end

Timer(_ -> revive(task), 1; interval = 3)

turn_recording!(onoff) = turn!(logbook, onoff)
read_state() = state::State

end
