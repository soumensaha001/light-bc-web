#!/bin/sh

echo "working on project ${BC_PROJECT}"
oc project ${BC_PROJECT}
oc status

echo "Welcome"
echo "- Typically you will want to create the project first"
echo "- The install of tekton is optional. The tekton install allows setting up triggers and webhooks"
echo "- After setting up the namespace you will proceed to install mysql"
echo "- Next populate the mysql database"
echo "- Next you install the generic pipeline using the light-bc-inventory repo"
echo "- Next you return to this repo to setup and run the pipeline to deploy the user interface"

PS3='Please enter your choice: '
options=("delete namespace" "init namespace" "install mysql non-persistent" "install mysql persistent" "install tekton" "setup pipeline" "run pipeline" "load db" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "delete namespace")
            #1 remove the namespace with all of its resources
            echo "************************ Deleting namespace ${BC_PROJECT} ******************************************"        
            oc delete project ${BC_PROJECT}
            echo "note: though the persistent volume claim is removed, the persistent volume will still have a reference to that claim (data is not lost)."
            break
            ;;
        "init namespace")

            echo "************************ Initializing namespace ${BC_PROJECT} ******************************************" 
            
            # 1
            echo "creating namespace"
            oc new-project ${BC_PROJECT} 

            # 2 - TODO replace image with non-priviledged user
            echo "allow the default account to run in priviledged mode (hint: not a best practice)"
            oc adm policy add-scc-to-user anyuid system:serviceaccount:${BC_PROJECT}:default

            # 3 - store access token to docker hub 
            echo "create access key to docker hub account"
            oc create secret docker-registry regcred \
            --docker-server=https://index.docker.io/v1/ \
            --docker-username=${DOCKER_USERNAME} \
            --docker-password=${DOCKER_PASSWORD} \
            --docker-email=${DOCKER_EMAIL}
            #oc get secret regcred

            # 4 - link the pipeline service account to the regcred secret to allow a push
            echo "giving the pipeline account the access key"
            oc apply -f link-sa-pipeline.yaml
            oc describe secret regcred

            # 5 - make the pipeline-account (sa) cluster-admin. 
            # - is that necessary?
            # - note: the pipeline-account does not exist yet.
            echo "go wild and make the pipeline service account CLUSTER admin (hint: not a best practice)"
            oc apply -f clusteradmin-rolebinding.yaml

            echo "done, please proceed to installing mysql"
            echo "NOTE: when you install mysql with persistent storage then you need a cluster that can honor persistent volume claim requests"

            break
            ;;
        "install mysql non-persistent")
            echo "************************ installing mysql in non persistent mode (data will be lost in various situations) ******************************************" 
            oc apply -f mysql.yaml
            echo "done, please proceed to loading mysql with data."            
            break
            ;;
        "install mysql persistent")
            echo "************************ installing mysql in non persistent mode (data will not be lost as long as your persistent storage is OK) ******************************************" 
            oc apply -f mysql-persistent.yaml
            echo "done, please proceed to loading mysql with data."             
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
        "setup pipeline")
            echo "setup pipeline"
            #1 setup tekton resources
            echo "************************ setup Tekton PipelineResources ******************************************"
            sed -i "s/ibmcase/${DOCKER_USERNAME}/g" ../tekton/PipelineResources/bluecompute-web-pipeline-resources.yaml
            sed -i "s/phemankita/${GIT_USERNAME}/g" ../tekton/PipelineResources/bluecompute-web-pipeline-resources.yaml
            #cat ../tekton/PipelineResources/bluecompute-web-pipeline-resources.yaml
            oc apply -f ../tekton/PipelineResources/bluecompute-web-pipeline-resources.yaml
            #oc get PipelineResources
            tkn resources list
            break
            ;;
        "run pipeline")
            echo "run pipeline"
            tkn pipeline start build-and-deploy -r git-repo=git-source-web -r image=docker-image-web -p deployment-name=web-lightblue-deployment
            break
            ;;
        "load db")
            echo "load db"
            POD=$(oc get po | grep mysql | awk '{print $1}')
            echo "discovered pod $POD"
            #oc cp mysql-data.sql $POD:/tmp/mysql-data.sql
            #oc rsh $POD ls -l /tmp/mysql-data.sql
            oc rsh $POD mysql -udbuser -pPass4dbUs3R inventorydb < mysql-data.sql
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
echo "hello kitty catt"
