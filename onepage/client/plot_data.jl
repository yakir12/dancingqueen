using GLMakie, Statistics

const nleds = prefs["leds"]["n"]
const w = prefs["camera"]["width"]
const h = prefs["camera"]["height"]

function get_indices(i1, i2)
    if i1 == i2
        [i1]
    elseif i1 < i2
        collect(i1:i2)
    else
        [i1:nleds; 1:i2]
    end
end

# topoint(p) = reverse(Tuple(round.(Int, p)))

# ImageDraw.draw!(img, ::Nothing) = nothing
# ImageDraw.draw!(img, b) = draw!(img, CirclePointRadius(Point(topoint(b.c)), round(Int, 0.01max(w, h))), RGB{N0f8}(1, 0, 1))

function update_leds!(positions, colors, ls)
    R = 0.45w
    for index in get_indices(ls.i1, ls.i2)
        θ = 2π/nleds*index
        p = R*SV(reverse(sincos(θ))) + SV(w/2, h/2):wq

        positions
        draw!(img, CirclePointRadius(ImageDraw.Point(topoint(p)), round(Int, R*sin(π/nleds))), ls.color)
    end
end



radius = 250

transform!(df, [:x, :y] => ByRow(Point2f) => :positions)
μ = mean(df.positions)

transform!(df, :positions => ByRow(p -> p - μ) => :positions)


fig = Figure()
ax = Axis(fig[1,1], aspect = AxisAspect(1), alignmode=Inside())
hidespines!(ax)
hidedecorations!(ax)
lines!(ax, Circle(zero(Point2f), radius), color = :gray)
positions = Observable([zero(Point2f)])
rotations = Observable(0.0)
scatter!(ax, positions; color = :red, markerspace=:data, markersize=radius/10, marker = '→', rotations)
sun_positions = Observable([zero(Point2f)])
colors = Observable(zero(RGB{N0f8}))
scatter!(ax, sun_positions; colors)
sg = SliderGrid(fig[2, 1],
                (label = "Time", range = 1:nrow(df), startvalue = 1, format = i -> string(df.time[i]))
)
on(sg.sliders[1].value) do i
    positions[] = [df.positions[i]]
    rotations[] = df.θ[i]
    sun_positions
end


# TODO: unify the functions that:
#  - compose the instructions to the MC
#  - draw on the image sent to the client
#  - post-hoc plot the saved data
# All three must look exactly the same
# add extra reported stats to the plotting
# maybe add some of that to the monitoring?
