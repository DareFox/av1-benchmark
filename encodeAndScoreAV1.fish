#!/bin/env fish

set sample $argv[1]
set basenameSample $(basename $sample)
set basedirSample $(dirname $sample)
set exportExtension "mkv"

# ffmpeg uses only 1 thread for vmaf scoring
set parallelVmafJobs 5

set resultsFolder $basedirSample/$basenameSample-RESULTS

if not test -d $resultsFolder
    mkdir $resultsFolder
end

set processedFilesList $resultsFolder/processed

set gnuTimeFormat "Time result\nCommand: %C\nExit code: %x\n\nSimplified elapsed real time: %E\nElapsed real time: %es\n\nCPU percentage (user+system/time): %P\nCPU-seconds used in kernel: %S\nCPU-seconds used in user space: %U\n\nMajor or I/O page faults: %F\nMinor or recoverable page faults: %R\n\nFile system inputs: %I\nFile system outputs: %O\n\nLife-time max resident set size: %Mkb\nAvg resident set size: %tkb\nAvg total memory use (data+stack+text): %Kkb\nAvg unshared data area: %Dkb\nAvg unshared stack space: %pkb\nAvg shared text space: %X\n\nSystem's page size: %Z bytes\n\nNumber of swaps of main memory: %W\nNumber of context-switched swaps: %c\nNumber of waits: %w\n\nNumber of socket messages received: %r\nNumber of socket messages sent: %s\nNumber of signals delibered to the process %k"

for preset in 6 7 8 9 10 
    for crf in 20 22 24 26
        for filmGrain in 0 3 6 9 11
            for fastDecode in 0 1
                set basenameExport "sample-$sample=preset=$preset-crf=$crf-filmGrain=$filmGrain-fastDecode=$fastDecode"
                set filenameExport "$basenameExport.$exportExtension"
                set ffmpegLogFileExport "$basenameExport-time=$(date -u +%Y-%m-%dT%H:%M:%S%Z).ffmpeg.log"
                set gnuTimeLogFileExport "$basenameExport-time=$(date -u +%Y-%m-%dT%H:%M:%S%Z).gnu-time.log"

                # Check if file was already processed
                if cat $processedFilesList | grep --quiet "^$basenameExport\$"   
                    echo "$basenameExport was already processed. Skipping..."
                    continue
                end

                set -x FFREPORT file=$ffmpegLogFileExport
                echo -n "----------"
                echo -n "FFREPORT file set to $ffmpegLogFileExport"
                
                # Auto clean on CTRL+C
                trap "echo \nCaught SIGINT! Removing all $basenameExport\* files \(because they are unfinished\).; ./removeFilesByBasename.fish $resultsFolder $basenameExport; exit" SIGINT

                command time -f $gnuTimeFormat ffmpeg -report -i $sample -c:v libsvtav1 -preset $preset -crf $crf \
                -svtav1-params film-grain=$filmGrain:fast-decode=$fastDecode -map 0:v -map 0:a -c:a libopus -b:a 128k \ 
                $resultsFolder/$filenameExport 2>&1 | tee $gnuTimeLogFileExport
    
                # Remove auto clean
                trap - SIGINT

                # Add to processed list
                echo $basenameExport >> $processedFilesList
            end
        end
    end
end

echo "Starting VMAF scoring"
parallel -j $parallelVmafJobs ./scoreVideo.fish $resultsFolder $sample ::: $resultsFolder/*.mkv
echo "Finished"
