#!/bin/sh

echo "working on project ${BC_PROJECT}"
oc project ${BC_PROJECT}
oc status

PS3='Please enter your choice: '
options=("delete namespace" "init namespace" "install tekton" "Quit")
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

            # 5 - make the pipeline-account (sa) cluster-admin. 
            # - is that necessary?
            # - note: the pipeline-account does not exist yet.
            oc apply -f clusteradmin-rolebinding.yaml

            # 6 - setup mysql database 
            oc apply -f mysql.yaml

            break
            ;;
        "install tekton")
            echo "installing tekton"

            # create project tekton-pipelines
            oc new-project tekton-pipelines

            # deploy various tekton artefacts into the openshift-pipelines namespace 
            oc project openshift-pipelines

            # deploy the dashboard
            # TODO: make the version configurable  
            # TODO: check the md5sum
            oc apply --filename https://github.com/tektoncd/dashboard/releases/download/v0.5.2/openshift-tekton-dashboard-release.yaml

            # increase the gateway time-out
            oc annotate route tekton-dashboard --overwrite haproxy.router.openshift.io/timeout=2m -n tekton-pipelines

            # install the tekton triggers 
            # TODO: make the version configurable  
            # TODO: check the md5sum
            oc apply --filename https://storage.googleapis.com/tekton-releases/triggers/previous/v0.2.1/release.yaml

            # install the tekton webhook extensions
            # TODO: make the version configurable  
            # TODO: check the md5sum
            curl -L https://github.com/tektoncd/dashboard/releases/download/v0.5.2/openshift-tekton-webhooks-extension-release.yaml -o openshift-tekton-webhooks-extension-release.yaml
            sed -i "s/{openshift_master_default_subdomain}/$APPS_LB/g" openshift-tekton-webhooks-extension-release.yaml
            grep $APPS_LB openshift-tekton-webhooks-extension-release.yaml
            oc apply -f  openshift-tekton-webhooks-extension-release.yaml
            rm openshift-tekton-webhooks-extension-release.yaml

            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
echo "hello kitty catt"
