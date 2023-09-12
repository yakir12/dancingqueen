# TODO:
# add labels and current value to the sliders
cell([ 
      imageview(src=:imageurl, basic=true, style="max-width: $(Main.h)px")
      toggle(:recording_label, :recording_on)
     ],
    [
     slider(0:360, :bearing)
    ],
    [
     slider(-1:0.1:1, :link_factor)
    ])
