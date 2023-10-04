module App
using GenieFramework

@genietools

@app begin
    @in options = ["opt1", "opt2", "opt3"]
    @in chosen = 0
    @onchange chosen begin
        println(options[chosen + 1])
    end
end

function ui()
    row(@recur("(opt, index) in options"), [radio("tmp", :chosen, val = :index, label=:opt)])
end

@page("/", ui)

end

