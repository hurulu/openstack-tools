#!/bin/bash
export OS_AUTH_URL=
export OS_TENANT_NAME=
export OS_USERNAME=
export OS_PASSWORD=
db_password=
if [ $# -ne 2 ];then
echo "$0 instance_uuid dest_compute_node"
exit
fi
uuid=$1
dest_host=$2
echo "stop instance $uuid ..."
original_state=`nova show $uuid|grep vm_state|awk '{print $4}'`
if [ $original_state == "active" ];then
	nova stop $uuid
	echo "sleep 10 for the instance to shut off..."
	sleep 10
fi
echo "backup /instances/$uuid to /instances/$uuid.bak"
mv /instances/$uuid /instances/${uuid}.bak
echo "old host in database : "
echo "select host,node,launched_on from instances where uuid='$uuid';"|mysql -unova -p$db_password -h mysql-01 nova
echo "set to new host in mysql ..."
echo "update instances set host='$dest_host',node='$dest_host',launched_on='$dest_host' where uuid='$uuid';"|mysql -unova -p$db_password -h cw-mysql-01 nova
echo "new host in database : "
echo "select host,node,launched_on from instances where uuid='$uuid';"|mysql -unova -p$db_password -h mysql-01 nova
echo "rsync /instances/$uuid ..."
rsync -e ssh -av /instances/$uuid.bak/* ${dest_host}:/instances/$uuid/
image_file=`file /instances/$uuid.bak/disk|sed 's/.*has backing file (path //g'|cut -d \) -f1`
ssh $dest_host "test -f $image_file"
if [ $? -ne 0 ];then
	echo "rsync -e ssh -av $image_file ${dest_host}:$image_file   ..."
	rsync -e ssh -av $image_file ${dest_host}:$image_file
fi
ssh $dest_host "chown -R nova.nova /instances/$uuid"
echo "restart nova-network on localhost ..."
iptables -F
killall -9 dnsmasq
service nova-compute restart
service nova-network restart
sleep 5
/usr/local/bin/firewall.sh start &>/dev/null
echo "restart nova-network on $dest_host ..."
ssh $dest_host "killall -9 dnsmasq ; service nova-network restart;service nova-compute restart"
if [ $original_state == "active" ];then
	echo "reboot the instance..."
	nova reboot --hard $uuid
fi
nova show $uuid
