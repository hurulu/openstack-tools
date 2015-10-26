#!/usr/bin/env python

import sys,string
import os
import subprocess
from novaclient import client
from keystoneclient.v2_0 import client as kc


auth_username = os.environ.get('OS_USERNAME')
auth_password = os.environ.get('OS_PASSWORD')
auth_tenant = os.environ.get('OS_TENANT_NAME')
auth_url = os.environ.get('OS_AUTH_URL')
search_opts = {
        'all_tenants': True
}

def get_tenant_dict(client):
    result_list = {}
    for tenant in client.tenants.list():
        result_list[tenant.__dict__['id']] = tenant.__dict__['name']
    return result_list

def get_user_dict(client):
    result_list = {}
    for user in client.users.list():
        if user.__dict__.has_key('name'):
                result_list[user.__dict__['id']] = user.__dict__['name']
    return result_list
nova = client.Client("1.1",auth_username,auth_password,auth_tenant,auth_url)

source_host = sys.argv[1]
print source_host
host_aggregate = {}
for aggregate in  nova.aggregates.list():
        aggregate_id = aggregate._info.copy()['id']
        for host in aggregate._info.copy()['hosts']:
                if host_aggregate.has_key(host):
                        print "Warning: " + host + "\n"
                else:
                        host_aggregate[host] = aggregate_id

#print host_aggregate
aggregate_id = host_aggregate[source_host]
print aggregate_id
aggregate_hosts = nova.aggregates.get(aggregate_id)._info.copy()['hosts']
#print aggregate_hosts


array = {}
for hypervisor in  nova.hypervisors.list():
        hypervisor_host = hypervisor._info.copy()['hypervisor_hostname']
        if hypervisor_host in aggregate_hosts:
                array[hypervisor._info.copy()['hypervisor_hostname']] = hypervisor._info.copy()['free_ram_mb']
                output = subprocess.check_output(['nova', 'service-list','--host',hypervisor_host,'--binary','nova-compute'])
                print output
print array
#print nova.services.list
