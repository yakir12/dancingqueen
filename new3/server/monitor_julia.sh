#!/bin/sh

while true
do 
    ps -C julia -o %cpu,%mem | sed "s#^#$(date +%Y/%m/%d/%H:%M:%S.%3N) #" >> monitor_julia.log
    sleep 1
done
