#!/bin/sh

echo "working on project ${BC_PROJECT}"
oc project ${BC_PROJECT}
oc status

PS3='Please enter your choice: '
options=("delete namespace" "init namespace" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "delete namespace")
            echo "Deleting namespace ${BC_PROJECT}"
            oc delete project ${BC_PROJECT}
            break
            ;;
        "init namespace")
            echo "Initializing namespace ${BC_PROJECT}"

            # 1
            oc new-project ${BC_PROJECT} 

            # 2 - todo replace image with non-priviledged user
            oc adm policy add-scc-to-user anyuid system:serviceaccount:${BC_PROJECT}:default

            # 3 - store access token to docker hub 
            oc create secret docker-registry regcred \
            --docker-server=https://index.docker.io/v1/ \
            --docker-username=${DOCKER_USERNAME} \
            --docker-password=${DOCKER_PASSWORD} \
            --docker-email=${DOCKER_EMAIL}
            #oc get secret regcred

            # 4 - link the pipeline service account to the regcred secret to allow a push
            oc apply -f link-sa-pipeline.yaml
            oc describe secret regcred


            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
echo "hello kitty catt"
