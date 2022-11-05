#!/bin/env fish

set sample $argv[1]
set basenameSample $(basename $sample)
set basedirSample $(dirname $sample)

set resultsFolder $basedirSample/$basenameSample-RESULTS

if not test -d $resultsFolder
    mkdir $resultsFolder
end


