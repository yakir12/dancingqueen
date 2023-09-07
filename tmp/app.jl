module App

using GenieFramework

include("lib/MyModule.jl")

using .MyModule

@info "definition is defined here" Main.definition

route("/") do
    "hello"
end

end
