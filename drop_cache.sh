#!/bin/sh
i=0
while [ $i -lt 3600 ] ; do
  echo 3 > /proc/sys/vm/drop_caches
  sleep 1
  i=`expr $i + 1`
done
