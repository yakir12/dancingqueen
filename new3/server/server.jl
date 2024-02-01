using DancingQueen
using Oxygen

setup, get_bytes, get_state = main();

frame() = binary(collect(get_bytes()))
state() = get_state()

@get "/frame" frame

@get "/state" state

@post "/setup" function(req)
    setup[] = json(req, Dict)
    return nothing
end

serve(access_log=nothing, host="0.0.0.0", port=8000)

