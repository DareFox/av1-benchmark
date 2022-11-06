#!/bin/env fish
set folder $argv[1]
set processedFileList processed
set csvFile $folder/results.csv

if not test -f $folder/$processedFileList
    echo "file '$processedFileList' doesn't exist in $folder"
    exit 1
end

echo "Preset;CRF;Film Grain Level;Is Fast Decode used;VMAF Score;Encode elapsed time in seconds;Sample name" > $csvFile

cat $folder/$processedFileList | while read -l filename
    set encodeTimeSeconds (cat $filename*.gnu-time.log | grep -Po '(?<=Elapsed real time: )\\S*(?=s)')
    set vmafScore (cat $filename.vmaf.log | grep -Po '(?<=VMAF score: )\\S*') 
    set preset (echo $filename | grep -Po '(?<=preset=)[^-]*')
    set crf (echo $filename | grep -Po '(?<=crf=)[^-]*')   
    set filmGrain (echo $filename | grep -Po '(?<=filmGrain=)[^-]*')   
    set fastDecode (echo $filename | grep -Po '(?<=fastDecode=)[^-]*')   
    
    echo "$preset;$crf;$filmGrain;$fastDecode;$vmafScore;$encodeTimeSeconds;$filename" >> $csvFile
    echo "Processed $filename"
end
