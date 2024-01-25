# using Dates
using DancingQueen
using Oxygen
using HTTP
# using JSON3

setup, get_bytes, get_state = main();

@get "/frame" function(req::HTTP.Request)
    binary(collect(get_bytes()))
end

@get "/state" function(req::HTTP.Request)
    # TODO can't have θ in the field name of beetle
    get_state()
end

serve(host="0.0.0.0", port=8000)



