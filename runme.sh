#!/bin/bash
 ./headtrack64 --xml /usr/share/opencv/haarcascades/haarcascade_frontalface_alt.xml --period 10 &
 sleep 3;
fgfs --generic=socket,in,10,3127.0.0.1,49405,udp,headtrack --prop:/sim/headtracking/enabled=1
