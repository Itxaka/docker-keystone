#!/bin/bash
set -x

keystone-all &
KEYSTONE_PID=$!
EXTERNAL_IP=`ifconfig eth0| sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`

keystone-manage db_sync

export OS_SERVICE_TOKEN=ADMIN_TOKEN
export OS_SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0

keystone tenant-create --name admin --description "Admin Tenant"
keystone user-create --name admin --pass admin --email admin@admin.com
keystone role-create --name admin
keystone user-role-add --user admin --tenant admin --role admin
keystone tenant-create --name service --description "Service Tenant"
keystone service-create --name keystone --type identity --description "OpenStack Identity"

keystone endpoint-create \
  --service-id $(keystone service-list | awk '/ identity / {print $2}') \
  --publicurl http://$EXTERNAL_IP:5000/v2.0 \
  --internalurl http://$EXTERNAL_IP:5000/v2.0 \
  --adminurl http://$EXTERNAL_IP:35357/v2.0 \
  --region regionOne


kill $KEYSTONE_PID

keystone-all
