# TODO:
# maybe add ° to teh labels...

cell([
      row([
           imageview(src=:imageurl, basic=true, style="max-width: $(Main.h)px")
           toggle(:recording_label, :recording_on)
          ])
      row([
           h6("Bearing")
           slider(0:10:360, :bearing, markers=true, label=true, format='°')
          ])
      row([
           h6("Link factor")
           slider(-1:0.1:1, :link_factor, markers=true, label=true)
          ])
     ])
