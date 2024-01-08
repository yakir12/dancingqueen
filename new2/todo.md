[x] Figure out what image dimensions, and fps are best
[x] Test and see what is the best way to crop that image into a w x w square
[x] test the schema, and the reports (specifically the camera field), make sure a fail reports
[x] Mark the location of the arena and the posts to center it all around the ring (tape and string)
[x] Calculate the smallest window size in the detector to match the largest apriltag on the arena
[x] post processing: make sure it all looks correctly, and fits exactly with reality (no mirroring, counter rotations, switching cameras etc)
[x] tweak the fps of the client to see if that helps maxing out the fps of the cameras
[x] Benchmark fps to ensure we're not dropping frames
[x] replace global Dicts with enums
[x] Discover the largest distance between the camera and the arena such that the apriltag is still reliably detectable
[ ] Get an IR strobe and place it well (must be a few in the lab), if not, get a lamp (BUY A LIHJY BULB)
[ ] Glue the camera to its holder (hot glue)
[ ] Center the camera above the center of the ring, Rotate the camera to align with North, Level the camera so all the lines are straight (GET A GRID FOR THE FLOOR)

[ ] Measure the calibration parameters needed for approximate transformation from pixel to real-world coordinates: ring center in image, ring zero azimuth relative to image axes, cm per pixel. 
[ ] Make sure you can reproduce the original data from the saved/logged data (the plotted data needs to look like what it does on the screen and the LEDs): ./DancingQueen/src/display.jl#L28
[ ] Experiment without global model
[ ] Clean the code base

[ ] Blacken out the LEDs of the arduino and rpi (BUY BLACKING GLUE)
[ ] Get a box with a fan for the rpi
[ ] Close the tent, fix it up, etc
[ ] Add instructions

[ ] Test it on Elin

[ ] build .sh script for the rpi
[ ] It is advisable to set force_turbo=1 in /boot/firmware/config.txt to ensure the CPU clock does not get throttled during the video capture. See the force_turbo documentation for further details.
[ ] install from fresh and repreduce it reliably
