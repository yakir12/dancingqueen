cell([
      row([
           imageview(src=:imageurl, basic=true, style="max-width: $(Main.h)px")
           toggle(:recording_label, :recording_on)
          ])
      row([
           h6("Link factor")
           slider(-1:0.1:1, :link_factor, markers=true, label=true)
          ])
     ])
