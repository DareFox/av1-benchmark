#!/bin/env fish
set outputTo $argv[1]
set original $argv[2]

set distorted $argv[3]

printf "VMAF Rating\n\tOriginal: $original\n\tDistorted: $distorted\n"

set nameDistorted $(basename $distorted)
set logPath $outputTo/$nameDistorted.vmaf.log

set gnuTimeFormat "Time result\nCommand: %C\nExit code: %x\n\nSimplified elapsed real time: %E\nElapsed real time: %es\n\nCPU percentage (user+system/time): %P\nCPU-seconds used in kernel: %S\nCPU-seconds used in user space: %U\n\nMajor or I/O page faults: %F\nMinor or recoverable page faults: %R\n\nFile system inputs: %I\nFile system outputs: %O\n\nLife-time max resident set size: %Mkb\nAvg resident set size: %tkb\nAvg total memory use (data+stack+text): %Kkb\nAvg unshared data area: %Dkb\nAvg unshared stack space: %pkb\nAvg shared text space: %X\n\nSystem's page size: %Z bytes\n\nNumber of swaps of main memory: %W\nNumber of context-switched swaps: %c\nNumber of waits: %w\n\nNumber of socket messages received: %r\nNumber of socket messages sent: %s\nNumber of signals delibered to the process %k"

if test -f $logPath
    if cat $logPath | grep -Poq '(?<=VMAF score: )\\S*'
        printf "$distorted was already scored\nYou can get score in $logPath.\nSkipping..."
        exit 1
    else
        printf "VMAF log does exist, but doesn't have score. Maybe because it's borked."
        printf "Renaming old VMAF log to create a valid score"
        mv $logPath $logPath.old
    end
end

printf "\nLogs will be written to $outputTo\n"

trap "echo \nCaught SIGINT!\nRemoving current log \($logPath\); rm $logPath; exit" SIGINT
command time -f $gnuTimeFormat ffmpeg -i $distorted -i $original -threads 12 -filter_complex libvmaf -f null - 2>&1 | tee $logPath
trap - SIGINT
