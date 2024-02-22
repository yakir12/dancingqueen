module DancingQueen

using Dates
using Observables, StaticArrays, AprilTags, JSON3, ImageDraw, COBSReduced, ImageCore
import TOML
import ColorTypes: RGB, N0f8


export start

const path2preferences = joinpath(@__DIR__, "..", "preferences.toml")
const path2data = joinpath(@__DIR__, "..", "..", "data")
const prefs = TOML.parsefile(path2preferences)
const nleds = prefs["arena"]["nleds"]
const w = prefs["camera"]["width"]
const h = prefs["camera"]["height"]
const fps = prefs["camera"]["fps"]
const baudrate = prefs["arena"]["baudrate"]

const Color = RGB{N0f8}
const SV = SVector{2, Float64}
const SVI = SVector{2, Int}
const sz = SVI(w, h)

include("structs.jl")

using LibSerialPort

const serialport = Ref{SerialPort}()
const detector = Ref{DetectoRect}()
function __init__()
    detector[] = DetectoRect()
    # serialport[] = get_port()
    serialport[] = open(first(get_port_list()), baudrate)
end

include("detection.jl")
include("tracking.jl")
include("leds.jl")
include("logs.jl")
include("display.jl")
include("settings.jl")
include("camera.jl")

function connect(img)
    setups_dict = Observable(Dict("setups" => [JSON3.read(JSON3.write(zero(Setup)), Dict)]))
    setups = map(setups_dict) do dict
        Setup.(dict["setups"])
    end
    chosen = map(_ -> 1, setups)
    safe_chosen = Observable(1)
    on(chosen) do chosen
        if 1 ≤ chosen ≤ length(setups[])
            safe_chosen[] = chosen
        end
    end
    setup = map(i -> setups[][i], safe_chosen)
    logbook = Ref(LogBook())
    on(setup) do setup
        close_log!(logbook[])
        if setup.label ≠ "Off"
            open_log!(logbook[], setup)
        end
    end
    suns = map(su -> su.suns, setup)
    # img = Observable(PermutedDimsArray(rand(Color, h, w), (2,1)))
    beetle = Observable{Union{Nothing, Beetle}}()
    map!(beetle, img) do img
        detector[](img)
    end
    # map!(img -> detector[](img), beetle, img)
    on(beetle) do beetle
        if !isnothing(beetle)
            track(beetle)
            rotate!.(suns[])
            notify(suns)
        end
    end
    leds = map(suns; ignore_equal_values=true) do suns
        LEDSun.(suns)
    end
    on(writeLEDs, leds)
    on(leds) do leds
        log!(logbook[], beetle[], leds)
    end

    get_frame() = _get_frame(img[], beetle[], leds[])

    return (setups_dict, chosen, get_frame)
end

function start()
    cam = Camera(w, h, fps)
    setups_dict, chosen, get_frame = connect(cam.img)
    # cam = opencamera("/dev/video2")
    # cam = opencamera()
    # task = Threads.@spawn while isopen(cam)
    #     read!(cam, img[])
    #     notify(img)
    #     sleep(0.001)
    #     yield()
    # end
    return (cam.task, setups_dict, chosen, get_frame)
end

end # module DancingQueen

