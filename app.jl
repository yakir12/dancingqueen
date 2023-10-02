module App
using GenieFramework

@genietools

@app begin
    @in chosen = ""

    @onchange chosen begin
        println(chosen)
    end
end


function ui()
    Html.div(
             @on("keydown.a", "chosen=\"a\""),
             @on("keydown.b", "chosen=\"b\""),
             @on("keydown.c", "chosen=\"c\""),
             @on("keydown.d", "chosen=\"d\""),
             @on("keydown.e", "chosen=\"e\""),
             @on("keydown.f", "chosen=\"f\""),
             @on("keydown.g", "chosen=\"g\""),
             @on("keydown.h", "chosen=\"h\""),
             @on("keydown.i", "chosen=\"i\""),
             @on("keydown.j", "chosen=\"j\""),
             @on("keydown.k", "chosen=\"k\""),
             @on("keydown.l", "chosen=\"l\""),
             @on("keydown.m", "chosen=\"m\""),
             @on("keydown.n", "chosen=\"n\""),
             @on("keydown.o", "chosen=\"o\""),
             @on("keydown.p", "chosen=\"p\""),
             @on("keydown.q", "chosen=\"q\""),
             @on("keydown.r", "chosen=\"r\""),
             @on("keydown.s", "chosen=\"s\""),
             @on("keydown.t", "chosen=\"t\""),
             @on("keydown.u", "chosen=\"u\""),
             @on("keydown.v", "chosen=\"v\""),
             @on("keydown.w", "chosen=\"w\""),
             @on("keydown.x", "chosen=\"x\""),
             @on("keydown.y", "chosen=\"y\""),
             @on("keydown.z", "chosen=\"z\""),
             [row(radio(msg, :chosen, val = msg)) for msg in ("a", "b", "c")]
            )
end
@page("/", ui)
end

