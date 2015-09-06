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
keystone role-create --name _member_

keystone user-role-add --user admin --tenant admin --role admin
keystone tenant-create --name service --description "Service Tenant"
keystone service-create --name keystone --type identity --description "OpenStack Identity"

keystone user-create --name nova --pass nova
keystone user-role-add --user nova --tenant service --role admin
keystone service-create --name nova --type compute --description "OpenStack Compute"

keystone user-create --name glance --pass glance
keystone user-role-add --user glance --tenant service --role admin
keystone service-create --name glance --type image --description "OpenStack Glance"


keystone endpoint-create \
  --service-id $(keystone service-list | awk '/ identity / {print $2}') \
  --publicurl http://$EXTERNAL_IP:5000/v2.0 \
  --internalurl http://$EXTERNAL_IP:5000/v2.0 \
  --adminurl http://$EXTERNAL_IP:35357/v2.0 \
  --region regionOne

keystone endpoint-create \
  --service-id $(keystone service-list | awk '/ compute / {print $2}') \
  --publicurl http://$EXTERNAL_IP:8774/v2/%\(tenant_id\)s \
  --internalurl http://$EXTERNAL_IP:8774/v2/%\(tenant_id\)s \
  --adminurl http://$EXTERNAL_IP:8774/v2/%\(tenant_id\)s \
  --region regionOne

keystone endpoint-create \
  --service-id $(keystone service-list | awk '/ image / {print $2}') \
  --publicurl http://$EXTERNAL_IP:9292 \
  --internalurl http://$EXTERNAL_IP:9292 \
  --adminurl http://$EXTERNAL_IP:9292 \
  --region regionOne

nova-manage db sync
glance-manage db_sync

kill $KEYSTONE_PID

keystone-all &
glance-registry &
glance-api &
nova-api
