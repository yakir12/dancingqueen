@enum CamMode cmoff=0 cm2464=2464 cm1080=1080 cm1232=1232 cm480=480

camera_settings(cm::CamMode) = cm == cm480 ? (w = 640, h = 480, fps = 206) :
                               cm == cm1232 ? (w = 1640, h = 1232, fps = 83) :
                               cm == cm1080 ? (w = 1920, h = 1080, fps = 47) :
                               cm == cm2464 ? (w = 3280, h = 2464, fps = 21) :
                               (w = 640, h = 480, fps = 0)

get_camera_fov(cm::CamMode) = cm == cm480  ? 480/1232*48.8  :
                              cm == cm1232 ? 48.8           :
                              cm == cm1080 ? 1080/2464*48.8 :
                              cm == cm2464 ? 48.8           :
                              0.0

CamMode(setup::Dict) = CamMode(get(setup, "camera", 1080))


