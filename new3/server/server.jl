using DancingQueen
# using ImageTransformations
using Oxygen

# const buffer = Matrix{UInt8}(undef, 100, 100)

set_setup, get_bytes, get_state = main();

frame() = binary(vec(get_bytes()))
# frame() = binary(vec(imresize!(buffer, get_bytes())))
    
state() = get_state()

@get "/frame" frame

@get "/state" state

@post "/setup" function(req)
    set_setup(json(req, Dict))
    return nothing
end

serve(access_log=nothing, host="0.0.0.0", port=8000)

