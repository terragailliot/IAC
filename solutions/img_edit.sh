ffmpeg -i target.png -vf palettegen palette.png
ffmpeg -i input.mkv -i palette.png -lavfi paletteuse output.gif
