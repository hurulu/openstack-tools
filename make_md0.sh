#!/bin/bash
zpool destroy instances
fdisk /dev/sda <<EOF
d
n
p
1

+16G
n
p
2


t
1
fd
w
EOF
fdisk /dev/sdb <<EOF
d
n
p
1

+16G
n
p
2


t
1
fd
w
EOF

echo "deb http://au.archive.ubuntu.com/ubuntu/ trusty main restricted" >/etc/apt/sources.list
apt-get update
apt-get install -y --no-install-recommends mdadm
mdadm --create /dev/md0 -n 2 -l 10 /dev/sda1 /dev/sdb1
zpool create -f  -O primarycache=metadata -O compression=lz4 -O atime=off instances mirror sda2 sdb2 mirror sdc sdd mirror sde sdf
