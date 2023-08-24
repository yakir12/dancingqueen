module LogBooks

using Observables

export logit

const recording = Observable(false)

const buffer = []

on(recording) do is_recording
    if !is_recording && !isempty(buffer)
        ts, _ = first(buffer)
        file = joinpath("log", string(ts, ".log"))
        open(file, "w") do io
            println.(io, buffer)
        end
        @info "file $file has been saved to disk"
        empty!(buffer)
    end
end

function logit(x)
    recording[] && push!(buffer, x)
end


end
