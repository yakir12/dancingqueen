using ImageDraw, ImageView, Colors


w = 100
img = fill(colorant"black", w, w)
verts = CartesianIndex.([(2, 2), (2, w÷5), (w÷3, w÷5), (w÷3, 2), (2, 2)])
draw!(img, verts, BoundaryFill(3, 25; fill_value = colorant"green"); closed = true)
# draw!(img, Polygon(verts), colorant"red")
ImageView.closeall()
imshow(img)

img = fill(colorant"black", 640, 480)
verts = CartesianIndex.([(2, 2), (2, 100), (100, 200), (300, 10)])
# draw!(img, Polygon(verts))
draw!(img, verts, BoundaryFill(10, 10); closed = true)
imshow(img)




img = zeros(RGB, 7, 7)
expected = copy(img)
expected[2:6, 2:6] .= RGB{N0f8}(1)

verts = [CartesianIndex(2, 2), CartesianIndex(2, 6), CartesianIndex(6, 6), CartesianIndex(6, 2), CartesianIndex(2,2)]

fill_method = draw(img, verts, BoundaryFill(4, 4; fill_value = RGB(1), boundary_value = RGB(1)); closed = true)
