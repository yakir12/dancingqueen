import TOML
using DancingQueen
setup, img, i = main();
txt = read("settings.toml", String);
setups = TOML.parse(txt)["setups"];
push!(setups,  Dict("label" => "Off", "suns" => [Dict("link_factor" => 0)]));

setup[] = setups[2]


# Threads.@spawn for i in 1:100
#     setup[] = rand(setups)
# end
#
# Threads.@spawn for i in 1:100
#     setup[] = rand(setups)
# end
#
# setup[] = setups[2]

# using JpegTurbo
# using GenieFramework
# @genietools
#
# # a convinience function to convert pixel matrices to jpegs
# to_frame = String ∘ jpeg_encode
#
# # avoid writing to disk, when the user asks for a frame they get the latest one
# route("/frame") do
#     to_frame(img[])
# end
#
# @app Webcam begin
#     @out imageurl = "/frame"
# end myhandlers
#
# global model = init(Webcam, debounce = 0) |> myhandlers
#
# # add an (invalid) anchor to the imagepath in order to trigger a reload in the Quasar/Vue backend
# Stipple.js_methods(model::Webcam) = """updateimage: async function () { this.imageurl = "frame#" + new Date().getTime() }"""
#
# # have the client update the image every 33 milliseconds (should be changed to the camera's actual 1000/fps or less)
# Stipple.js_created(model::Webcam) = "setInterval(this.updateimage, 67)"
#
# # set the image style to basic to avoid the loading wheel etc
# ui() = [imageview(src=:imageurl, basic=true)]
#
# route("/") do
#     page(model, ui) |> html
# end
#
# Server.up()

# 1.5 ms for 3 suns

# using Dates, BenchmarkTools
# file = tempname()
# datetime = now()
# io = open(file, "w")
# f() = println(io, Dates.value(now() - datetime), ",", join(rand(3), ","), ",", join(rand(Int, 2*3), ","))
#
# @benchmark f() 2-7 μs 3 kb 42 alloc
#
# close(io)
#
# file = tempname()
# datetime = now()
# touch(file)
#
#
# x = rand(10)
# f() = open(file, "a") do io
#     println(io, x...)
# end
# @benchmark f()
#
# file = tempname()
# touch(file)
#
# x = rand(10)
# f() = open(file, "a") do io
#     write(io, x...)
# end
# f()
#
# read(file, Vector{Float64})
#
# ###
#
# file = tempname()
# datetime = now()
# touch(file)
# data = (Dates.value(now() - datetime), rand(3)..., rand(1:200, 2*3)...)
# f() = open(file, "a") do io
#     write(io, data...)
# end
# f()
#
# @benchmark f()
#
# io = open(file, "r")
# y = []
# for w in (Int, Float64, Float64, Float64, Int, Int, Int, Int, Int, Int)
#     push!(y, read(io, w))
# end
# close(io)
#
# ###
#
# file = tempname()
# datetime = now()
# touch(file)
# data = (Dates.value(now() - datetime), rand(3)..., rand(1:200, 2*3)...)
# g() = open(file, "a") do io
#     println(io, data...)
# end
# g()
#
# @benchmark g()
