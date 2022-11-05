#!/bin/env fish

set folder $argv[1]
set base $argv[2]

for file in $folder/$base*
    echo "Removing $file"
    rm $file
end
