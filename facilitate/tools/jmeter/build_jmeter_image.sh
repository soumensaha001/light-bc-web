#!/bin/bash

oc project tools
USER=$(oc whoami)
TOKEN=$(oc whoami -t)

oc project openshift-image-registry
oc adm policy add-role-to-user system:registry $USER
oc adm policy add-role-to-user system:image-builder $USER

oc project tools

oc expose svc image-registry -n openshift-image-registry
OCR=$(oc get routes -n openshift-image-registry | grep image-registry | awk '{ print $2 }')

docker build -t jmeter-prevail2020 .
docker images