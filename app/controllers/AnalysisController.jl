module AnalysisController
using GenieFramework.Genie.Renderer.Html
using GenieFramework.Genie.Requests
using .Main.App.StatisticAnalysis

function index()
    html("<h1>Welcome to the number analysis module</h1>
          <a href=/form>Numbers form</a>")
end

function analysis()
    N = parse(Int, postpayload(:N, 20))
    x = gen_numbers(N)
    m = sum(x / N)
    html(Renderer.filepath("pages/analysis.jl.html"), N=N, m=m)
end

function numbers()
    html(Renderer.filepath("pages/numbers.jl.html"), x=gen_numbers(payload(:N)))
end

end
