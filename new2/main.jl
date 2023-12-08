import TOML
using Dates
using StaticArrays, AprilTags, LibSerialPort, COBSReduced, ImageDraw
import ColorTypes: RGB, N0f8
using VideoIO

const SV = SVector{2, Float64}
const SVI = SVector{2, Int}
const Color = RGB{N0f8}

const path2preferences = "preferences.toml"
const path2data = "data"
const prefs = TOML.parsefile(path2preferences)
const baudrate = prefs["arena"]["baudrate"]
const nleds = prefs["arena"]["nleds"]
const tag_pixel_width = prefs["detection"]["tag_pixel_width"]
const widen_radius = prefs["detection"]["widen_radius"]
# const w = prefs["camera"]["width"]
# const h = prefs["camera"]["height"]

include("camera.jl")
include("detector.jl")
include("setup.jl")
include("tracker.jl")
include("leds.jl")
include("logs.jl")
include("display.jl")

function one_iter(cam, detector, tracker, leds, logbook, frame)
    snap(cam)
    beetle = detector(cam.img)
    tracker(beetle)
    tracker(setup.suns)
    leds(tracker.sun_θs)
    log!(logbook, beetle, leds)
    frame(cam.img, beetle, leds)
end

txt = read("settings.toml", String)
setups = TOML.parse(txt)


dict = setups["setups"][end]

logbook = LogBook(dict)
setup = Setup(dict)
cam = Camera("/dev/video2")
detector = DetectoRect(size(cam)..., tag_pixel_width, widen_radius)
tracker = Track(setup.suns)
leds = LEDs(baudrate, setup.suns)
frame = Frame(cam)

# task = Threads.@spawn while isopen(cam)
# sleep(15)
foreach(_ -> one_iter(cam, detector, tracker, leds, logbook, frame), 1:100)

close(cam)
close(detector)
close(leds)
close(logbook)

