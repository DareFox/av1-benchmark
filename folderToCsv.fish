#!/bin/env fish
set folder $argv[1]
set processedFileList processed
set csvFile $folder/results.csv

if not test -f $folder/$processedFileList
    echo "file '$processedFileList' doesn't exist in $folder"
    exit 1
end

echo "Encoded filename;Preset;CRF;Film Grain Level;Is Fast Decode used;VMAF Score;Encode elapsed time in seconds;Size in MiB" > $csvFile

cat $folder/$processedFileList | while read -l fileBasename
    set filename $folder/$fileBasename

    set encodeTimeSeconds (cat $filename*.gnu-time.log | grep -Po '(?<=Elapsed real time: )\\S*(?=s)' | sed 's/\./,/')
    set vmafScore (cat $filename.vmaf.log | grep -Po '(?<=VMAF score: )\\S*' | sed 's/\./,/') 
    set preset (echo $filename | grep -Po '(?<=preset=)\d*')
    set crf (echo $filename | grep -Po '(?<=crf=)\d*')   
    set filmGrain (echo $filename | grep -Po '(?<=filmGrain=)\d*')   
    set fastDecode (echo $filename | grep -Po '(?<=fastDecode=)\d*')   
    set mibSize (du -s -k $filename | awk '{printf "%.3f MiB %s\n", $1/1024, $2}' | grep -Po '.*(?=MiB)' | sed 's/\./,/')
    
    echo "$fileBasename;$preset;$crf;$filmGrain;$fastDecode;$vmafScore;$encodeTimeSeconds;$mibSize" >> $csvFile
    echo "Processed $fileBasename"
end
