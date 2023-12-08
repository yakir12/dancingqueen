using BenchmarkTools

txt = read("settings.toml", String)
setups = TOML.parse(txt)

dict = setups["setups"][end]
setup = Setup(dict)


logbook = LogBook(dict)
cam = Camera("/dev/video2")
detector = DetectoRect(size(cam)..., tag_pixel_width, widen_radius)
tracker = Track(setup.suns)
leds = LEDs(baudrate, setup.suns)
frame = Frame(cam)

# fetch an image that contains a tag in it
beetle = Ref{Union{Nothing, Beetle}}(nothing)
while isnothing(beetle[] )
    snap(cam)
    beetle[] = detector(cam.img)
end

# un/comment each row to see what its effect is
function fun(cam, detector, tracker, leds, logbook, frame)
    # snap(cam) # 100 ms 16 b 1 alloc
    # # the rest takes: 4 ms 4 mb 9204 alloc
    # # the rest takes: 1.5 ms 150 kb 1500 alloc, my PR
    beetle = detector(cam.img) # 500 μs 100 kb 30 alloc
    tracker(beetle) # 20 ns 16 b 1 alloc
    tracker(setup.suns) # 100 ns 600 b 2 alloc
    leds(tracker.sun_θs) # 133 ns 0 b 0 alloc * excluding writing to serial
    log!(logbook, beetle, leds) # 4 μs 5 kb 112 alloc *with no spawning
    # frame(cam.img, beetle[], leds) # 4 ms 3.7 mb 9760 alloc, most of the memory and allocations come from draw!ing the leds
    frame(cam.img, beetle, leds) # 500 μs  80 kb 2400 alloc, my PR
end
@benchmark fun(cam, detector, tracker, leds, logbook, frame)


# img = rand(RGB{N0f8}, 1000, 1000)
# f() = draw!(img, CirclePointRadius(Point(500, 500), 400))
# @benchmark f()
#
# g() = draw!(img, CircleThreePoints(Point(500, 100), Point(100, 500), Point(900, 500)))
# @benchmark f()

close(cam)
close(detector)
close(leds)
close(logbook)
