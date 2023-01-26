#!/bin/env fish

set sample $argv[1]

if not test -f $sample
    echo "$sample doesn't exist!"
    exit 1
end

set basenameSample $(basename $sample)
set basedirSample $(dirname $sample)
set exportExtension $(path extension $sample)

set resultsFolder $basedirSample/$basenameSample-RESULTS
set scriptFolder (dirname (status --current-filename))


if not test -d $resultsFolder
    mkdir $resultsFolder
end

set processedFilesList $resultsFolder/processed
set gnuTimeFormat "Time result\nCommand: %C\nExit code: %x\n\nSimplified elapsed real time: %E\nElapsed real time: %es\n\nCPU percentage (user+system/time): %P\nCPU-seconds used in kernel: %S\nCPU-seconds used in user space: %U\n\nMajor or I/O page faults: %F\nMinor or recoverable page faults: %R\n\nFile system inputs: %I\nFile system outputs: %O\n\nLife-time max resident set size: %Mkb\nAvg resident set size: %tkb\nAvg total memory use (data+stack+text): %Kkb\nAvg unshared data area: %Dkb\nAvg unshared stack space: %pkb\nAvg shared text space: %X\n\nSystem's page size: %Z bytes\n\nNumber of swaps of main memory: %W\nNumber of context-switched swaps: %c\nNumber of waits: %w\n\nNumber of socket messages received: %r\nNumber of socket messages sent: %s\nNumber of signals delibered to the process %k"

set presets 9 10 11 12 13
set crfs 22 24 26 28 30 32 34 36 38 40 42 44
set filmGrains 0
set fastDecodes 1
set colorBits "yuv420p10le" "yuv420p"

for preset in $presets
for crf in $crfs
for filmGrain in $filmGrains
for fastDecode in $fastDecodes
for color in $colorBits    

set basenameExport "sample=$sample-preset=$preset-crf=$crf-filmGrain=$filmGrain-fastDecode=$fastDecode-color=$color"
set filenameWithExtension "$basenameExport$exportExtension"
set filenameExportPath "$resultsFolder/$filenameWithExtension"

set ffmpegLogFileExport "$filenameExportPath.ffmpeg.log"
set gnuTimeLogFileExport "$filenameExportPath.gnu-time.log"

set dateStart (date -u +%Y-%m-%dT%H-%M-%S%Z)

# Check if file was already processed
if cat $processedFilesList | grep --quiet "^$filenameWithExtension\$"   
    echo "$basenameExport was already processed. Skipping..."
    continue
end

set -x FFREPORT file=$ffmpegLogFileExport
echo "----------"
echo "FFREPORT file set to $ffmpegLogFileExport"

# Auto clean on CTRL+C
trap "echo \nCaught SIGINT! Removing all $basenameExport\* files \(because they are unfinished\).; $scriptFolder/removeFilesByBasename.fish $resultsFolder $filenameWithExtension; exit" SIGINT

command time -f $gnuTimeFormat ffmpeg -report -i $sample -c:v libsvtav1 -preset $preset -crf $crf  \
-svtav1-params film-grain=$filmGrain:fast-decode=$fastDecode -pix_fmt $color  -map 0:v -map 0:a -c:a libopus -b:a 128k $filenameExportPath 2>&1 | tee $gnuTimeLogFileExport

# Remove auto clean
trap - SIGINT

# Append start date to beginning of log files
sed -i "1s/^/Started at $dateStart\n/" $ffmpegLogFileExport $gnuTimeLogFileExport

# Add exported file to processed list
echo $filenameWithExtension >> $processedFilesList

end 
end 
end 
end 
end
# In the end it doesn't even matter


echo "Starting VMAF scoring"

for file in $resultsFolder/*$exportExtension
     $scriptFolder/scoreVideo.fish $resultsFolder $sample $file
end
echo "Finished! :)"
