using Dates
using GLMakie, ImageCore
using HTTP
import ColorTypes: Gray, N0f8
using JSON3
using Observables

const fps = 25
const ip = "http://192.168.50.187:8000" # through ethernet
# const ip = "http://192.168.16.169:8000" # through hotspot
const nleds = 198

function bytes2img(b::Vector{UInt8}) 
    h = Int(sqrt(length(b)))
    colorview(Gray, normedview(reshape(b, h, h)))
end

function update_img!(img)
    HTTP.open("GET", "$ip/frame") do io
        while !eof(io)
            img[] = bytes2img(read(io))
        end
    end
end

function get_state()
    r = HTTP.request("GET", "$ip/state")
    return JSON3.read(String(r.body))
end

iterate_leds_indices_colors(msg, n) = zip((msg[i + 3:i + 4] for i in 1:5:5n), (msg[i:i + 2] for i in 1:5:5n))

collect_indices(i1, i2) = i1 ≤ i2 ? collect(i1:i2) : [i1:nleds; 1:i2]

tocolor(rgb) = RGBA(reinterpret(RGB{N0f8}, Tuple{UInt8, UInt8, UInt8}(rgb)), N0f8(1))

function update_leds!(leds_color, msg)
    n = Int(length(msg) / 5)
    fill!(leds_color[], zero(RGBA))
    for ((i1, i2), rgb) in iterate_leds_indices_colors(msg, n)
        color = tocolor(rgb)
        for i in collect_indices(i1, i2)
            leds_color[][i] = color
        end
    end
    notify(leds_color)
end

h = Observable(100)
img = Observable(bytes2img(Vector{UInt8}(undef, h[]^2)))
beetle_xy = Observable(Point2f(NaN, NaN))
beetle_dir = Observable(NaN)
rect = Observable(Recti(0, 0, h[], h[]))
leds_color = Observable([zero(RGBA{N0f8}) for _ in 1:nleds])

fig = Figure()
lims = @lift (0, $h, 0, $h)
ax = Axis(fig[1,1], aspect = AxisAspect(1), limits = lims)
image!(ax, img)
c = @lift $h/2
hlines!(ax, c, color=:white)
vlines!(ax, c, color=:white)
scatter!(ax, beetle_xy, markersize = 50, marker = '→', rotations=beetle_dir, color=:red)
poly!(ax, rect, color=:transparent, strokecolor=:green, strokewidth=1)
r = @lift $h/2.1
leds_xy = @lift [$r * Point2f(reverse(sincos(θ))) + Point2f($c, $c) for θ in range(0, 2π, nleds + 1)[1:end-1]]
scatter!(ax, leds_xy, color = leds_color, markersize = 20)
display(fig)

frame_task = @async while true
    ta = @async update_img!(img)
    ti = Timer(1/fps)
    wait(ti)
    fetch(ta)
end

state = Observable(get_state())

state_task = @async while true
    state[] = get_state()
end

throttled_state = throttle(1/fps, state)

on(throttled_state) do st
    x1, y1, x2, y2 = st.rect
    rect[] = Rect2i(x1, y1, x2 - x1, y2 - y1)
    if isnothing(st.beetle) 
        beetle_xy[] = Point2f(NaN, NaN) 
    else
        beetle_xy[] = Point2f(st.beetle.c)
        beetle_dir[] = st.beetle.theta
    end
    n = Int(length(st.leds) / 5)
    if all(all(!iszero, st.leds[i + 3:i + 4]) for i in 1:5:5n)
        update_leds!(leds_color, st.leds)
    end
end

setup = Observable(Dict("camera" => h[], "suns" => [Dict("link_factor" => 0)]))
on(setup) do setup
    HTTP.post("$ip/setup"; body=JSON3.write(setup))
    h[] = get(setup, "camera", 1080)
end

