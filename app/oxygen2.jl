using JpegTurbo, VideoIO, Oxygen

const cam = opencamera()
const img = Ref(read(cam))
const ui = """
<!DOCTYPE html><html>
  <head>
    <meta charset="utf-8" />
    <title>Oxygen App</title>
  </head>
  <body>
    <div>
        <img id="frame">
    </div>
  <script>
    frame = document.querySelector("#frame");

    async function loadImage() {
      frame.src = "frame#" + new Date().getTime()
    }

    setInterval(() => {
        loadImage();
    }, 33);
  </script>
  </body>
</html>
"""

# fetch fresh frames from the webcam
Threads.@spawn while isopen(cam)
    read!(cam, img[])
    sleep(1/90)
end

# define routes
@get "/" function()
    return ui
end

@get "/frame" function()
    return img[] |> jpeg_encode |> String
end

# start Oxygen server, in blocking mode
serve()
close(cam)
