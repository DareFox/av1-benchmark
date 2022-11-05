#!/bin/env fish
set outputTo $argv[1]
set original $argv[2]
set distorted $argv[3]

set nameDistorted $(basename $distorted)

ffmpeg -i $distorted -i $original -threads 12 -filter_complex libvmaf -f null - 2>&1 | tee $outputTo/$nameDistorted.vmaf.log
