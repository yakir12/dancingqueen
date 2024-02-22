h1("DancingQueen")
row([
     card(class="st-col col-12",
          [
           row([
                imageview(src=:imageurl, basic=true, style="max-width: $(Main.h)px")
               ])
           row([
                toggle(:recording_label, :recording_on)
               ])
          ])
    ])
row([
     h6("Link factor")
     slider(-1:0.1:1, :link_factor, markers=true, labelalways=true)
    ])
row([
     h6("Sun color")
     card(class="st-col col-12",
          [
           row([
                cell(size = 1, span("Red"))
                cell(slider(range(0, 1, 256), :red, markers=true, label=true, color="red"))
               ])
           row([
                cell(size = 1, span("Green"))
                cell(slider(range(0, 1, 256), :green, markers=true, label=true, color="green"))
               ])
           row([
                cell(size = 1, span("Blue"))
                cell(slider(range(0, 1, 256), :blue, markers=true, label=true, color="blue"))
               ])
          ])
    ])
row([
     h6("Sun width")
     slider(1:2:Main.nleds, :sun_width, markers=true, label=true)
    ])
