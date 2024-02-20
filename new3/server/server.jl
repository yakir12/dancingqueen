using DancingQueen
using ImageCore, ImageTransformations
using Oxygen

const buffer = Matrix{N0f8}(undef, 400, 400)

set_setup, get_bytes, get_state, task = main();

frame() = binary(collect(vec(rawview(imresize!(buffer, normedview(get_bytes()))))))

@get "/frame" frame

@get "/state" get_state

@post "/setup" function(req)
    set_setup(json(req, Dict))
    return "done"
end

serve(access_log=nothing, host="0.0.0.0", port=8000, async=true)

