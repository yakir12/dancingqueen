using GenieFramework
@genietools

@app begin
    @in slider_one = 1
    @in slider_two = 11

    @onchange slider_one println(slider_one)
    @onchange slider_two println(slider_two)

    @out tabgroup = "one"
end

function ui()
    [
     tabgroup(:tabgroup, 
              [
               tab(name="one", label="Tab one"),
               tab(name="two", label="Tab two")
              ])
     tabpanelgroup(:tabgroup, 
                   [
                    tabpanel("Inside tab one", name = "one", [slider(1:10, :slider_one, markers=true, labelalways=true)])
                    tabpanel("Inside tab two", name = "two", [slider(11:20, :slider_two, markers=true, labelalways=true)])
                   ])
    ]
end

@page("/", ui)

Server.up()

