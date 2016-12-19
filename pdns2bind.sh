#!/bin/bash

function usage {
  echo "$0 <create|update|delete> <zone>"
  exit 1
}

ACTION="$1"
ZONE="$2"
NS1_PREFIX="ns1"
NS2_PREFIX="ns2"
NS1_IP="127.0.0.1"
NS2_IP="127.0.0.1"
POWERDNS_PASS="password"
POWERDNS_API="http://127.0.0.1:8000/api/v1/servers/localhost/zones"

#
# create a zone
#
function create {

curl -v -X POST --data \
  '{"name":"'${ZONE}'.", "kind": "Native", "masters": [], "nameservers": []}' \
  -H 'X-API-Key: '${POWERDNS_PASS} \
  ${POWERDNS_API} > /dev/null 2>&1

exit

curl -v -X PATCH --data \
  '{"rrsets": [ {"name": "'${ZONE}'.", "type": "NS", "ttl": 3600, "changetype": "REPLACE", "records": [ {"content": "'${NS1_PREFIX}.${ZONE}'.", "disabled": false } ] } ] }' \
  -H 'X-API-Key: '${POWERDNS_PASS} \
  ${POWERDNS_API}/${ZONE} > /dev/null 2>&1

curl -v -X PATCH --data \
  '{"rrsets": [ {"name": "'${ZONE}'.", "type": "NS", "ttl": 3600, "changetype": "REPLACE", "records": [ {"content": "'${NS1_PREFIX}.${ZONE}'.", "disabled": false }, {"content": "'${NS2_PREFIX}.${ZONE}'.", "disabled": false } ] } ] }' \
  -H 'X-API-Key: '${POWERDNS_PASS} \
  ${POWERDNS_API}/${ZONE} > /dev/null 2>&1

curl -s -X PATCH --data \
  '{"rrsets": [ {"name": "'${NS1_PREFIX}.${ZONE}'.", "type": "A", "ttl": 3600, "changetype": "REPLACE", "records": [ {"content": "'${NS1_IP}'", "disabled": false } ] } ] }' \
  -H 'X-API-Key: '${POWERDNS_PASS} \
  ${POWERDNS_API}/${ZONE} > /dev/null 2>&1
curl -s -X PATCH --data \
  '{"rrsets": [ {"name": "'${NS2_PREFIX}.${ZONE}'.", "type": "A", "ttl": 3600, "changetype": "REPLACE", "records": [ {"content": "'${NS2_IP}'", "disabled": false } ] } ] }' \
  -H 'X-API-Key: '${POWERDNS_PASS} \
  ${POWERDNS_API}/${ZONE} > /dev/null 2>&1
rndc addzone ${ZONE} '{type slave; masters port 5353 { ::1; }; allow-notify { ::1; };};'
echo "done."

}

#
# notify update to bind
# (unnecessary if backend is MySQL)
#
function update {

pdnsutil increase-serial ${ZONE}
pdns_control notify ${ZONE}
echo "done."

}

#
# delete a zone
#
function delete {

curl -s -X DELETE -H 'X-API-Key: '${POWERDNS_PASS} ${POWERDNS_API}/${ZONE}
rndc delzone ${ZONE}
echo "done."

}

case $ACTION in
  "create")
      create
    ;;
  "update")
      update
    ;;
  "delete")
      delete
    ;;
  *)
      usage
esac

# HINT: http://docs.openstack.org/developer/designate/backends/bind9.html
# HINT2: http://jpmens.net/media/2013b/pdns-hidden-master.png
