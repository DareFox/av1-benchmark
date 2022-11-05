#!/bin/env fish

set folder $argv[1]
set base $argv[2]
set files $folder/$base*

for file in $files 
    echo "Removing $file..."
    rm $file
end
