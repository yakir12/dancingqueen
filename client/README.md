# DancingQueen

For the simplest mode of operation, edit the existing `settings.toml` file on the Desktop and run the program.

## Setup
In the settings file you descrive which setups you want to have available during your experiments. The settings file must have at least one setup. 

### Label
The labels are used to denote which setup should be on at each point in time. The are also useful later in data processing. The labels you use should be short but descriptive within the context of your experiment.

Each setup must have exactly one `label` (e.g. "One stationary green sun") and at least one sun. Two setups may not have the same `label`. No `label` may be called `Off` (that is reserved as an off-button). 

### Sun
The suns are the ersatz suns that the LEDs mimic. You may have as many suns as you wish.

#### Link factor
The link fators describe the degree the sun is linked to the orientation of the beetle. A link factor of zero means that the sun is not affected by the beetle at all. A link factor of -2 means that for each clockwise roation of 10° by the beetle, the sun will rotate counterclockwise by 20°.

Each sun must have a `link_factor` (a (can be a decimal) number that ranges from minus infinity to plus infinity).

#### Color
A color intensity sets the channel brightness of the LEDs composing their respective sun. 

Each sun must have at least one color intensity (an integer between 0 and 255). For example, to set the sun's color to the brightest green: `green = 255`, and for white set all three channels (`red`, `green`, and `blue`) to the intensity you require.

Color intensities that are not specified are assumed to be zero, so `green = 255` is understood to be:
```
red = 0
green = 255 
blue = 0
```

#### Width
The width controls the number of pixels used per sun.

Each sun can have width (an odd integer between 1 and the number of LEDs in the strip: 198). If left unspecefied, the default value is 1.

### Camera
The camera controls which mode you want to use in that specific setup. There are four modes, each with their own dis/advantages.

Each setup can have a camera mode. The camera can only be one of these values: 480, 1080, 1232, or 2464. If left unspecefied, the default value is 1080.

The following table shows how each camera mode compares to the other:

Mode|Resolution|FPS|Brightness|FOV|Max height|Arena width
---|---|---|---|---|---|---
480|480×480|206|low|19°|70 cm|24 cm
1232|1232×1232|83|high|48.8°|70 cm|64 cm
1080|1080×1080|47|high|21.4°|120 cm|45 cm
2464|2464×2464|21|high|48.8°|120 cm|109 cm
