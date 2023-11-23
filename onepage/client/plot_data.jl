using GLMakie, Statistics


# topoint(p) = reverse(Tuple(round.(Int, p)))

# ImageDraw.draw!(img, ::Nothing) = nothing
# ImageDraw.draw!(img, b) = draw!(img, CirclePointRadius(Point(topoint(b.c)), round(Int, 0.01max(w, h))), RGB{N0f8}(1, 0, 1))



fig = Figure()
ax = Axis(fig[1,1], aspect = AxisAspect(1), alignmode=Inside())
hidespines!(ax)
hidedecorations!(ax)
lines!(ax, Circle(zero(Point2f), ring_r), color = :gray)
scatter!(ax, zero(Point2f); color = :black, markerspace=:data, markersize=ring_r/10, marker = '+')
positions = Observable([zero(Point2f)])
rotations = Observable(0.0)
scatter!(ax, positions; color = :red, markerspace=:data, markersize=ring_r/10, marker = '→', rotations)
sun_positions = Observable([zero(Point2f)])
sun_centers = Observable([zero(Point2f)])
color = Observable([zero(RGB{N0f8})])
scatter!(ax, sun_positions; color)
scatter!(ax, sun_centers; color=:black)
sg = SliderGrid(fig[2, 1],
                (label = "Time", range = 0:Dates.value(df.time[end] - df.time[1]), startvalue = 0, format = ms -> string(df.time[1] + Millisecond(ms)))
)
on(sg.sliders[1].value) do ms
    i = findfirst(≥(df.time[1] + Millisecond(ms)), df.time)
    positions[] = [df.positions[i]]
    rotations[] = df.θ[i]
    empty!(sun_positions[])
    empty!(color[])
    empty!(sun_centers[])
    for leds in df.leds[i]
        for j in leds
            xy = index2coordinate(j)
            push!(sun_positions[], xy)
            push!(color[], leds.color)
        end
        c = center(leds)
        xy = index2coordinate(c)
        push!(sun_centers[], xy)
    end
    notify(sun_positions)
    notify(color)
    notify(sun_centers)
end
display(fig)

# TODO: unify the functions that:
#  - compose the instructions to the MC
#  - draw on the image sent to the client
#  - post-hoc plot the saved data
# All three must look exactly the same
# add extra reported stats to the plotting
# maybe add some of that to the monitoring?
