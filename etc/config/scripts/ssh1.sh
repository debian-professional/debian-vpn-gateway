#!/bin/bash

p1=$(cat ~/p1)
p2=$(cat ~/p2)
p3=$(cat ~/p3)
p4=$(cat ~/p4)
p5=$(cat ~/p5)
p6=$(cat ~/p6)
p7=$(cat ~/p7)
p8=$(cat ~/p8)
p9=$(cat ~//p9)
p10=$(cat ~/p10)

rm ~/p1 > /dev/null 2>&1
rm ~/p2 > /dev/null 2>&1
rm ~/p3 > /dev/null 2>&1
rm ~/p4 > /dev/null 2>&1
rm ~/p5 > /dev/null 2>&1
rm ~/p6 > /dev/null 2>&1
rm ~/p7 > /dev/null 2>&1
rm ~/p8 > /dev/null 2>&1
rm ~/p9 > /dev/null 2>&1
rm ~/p10 > /dev/null 2>&1

if [ -f /etc/config/cfg/nvpn ]; then
   ssh $p4 $p5 $p6 $p7 $p8 $p9 ${p10}
else
   sshpass $p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 ${p10}
fi


















