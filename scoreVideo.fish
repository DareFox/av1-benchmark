#!/bin/env fish
set original $argv[2]

set distorted $arv[3]
set nameDistorted (basename $distorted)

set outputTo $argv[1]

ffmpeg -i $distorted  -i $original -threads 12 -filter_complex libvmaf -f null - 2>&1 | tee $outputTo/$nameDistorted.vmaf.log
