module Monitor

using .Main.Cameras
using .Main.Detection
using .Main.LogBooks

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
end

logbook = LogBook()
camera = Camera()
dr = DetectoRect()

const state = State(snap!(camera), nothing)

task = Threads.@spawn while isopen(camera)
    state.img = snap!(camera)
    state.beetle = dr(state.img)
    log!(logbook, state.beetle)
end

Timer(_ -> revive(task), 1; interval = 3)

turn_recording!(onoff) = turn!(logbook, onoff)
read_state() = state::State

end
