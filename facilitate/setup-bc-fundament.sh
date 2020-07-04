#!/bin/sh

echo "working on project ${BC_PROJECT}"
oc project ${BC_PROJECT}
oc status

echo "Welcome"
echo "- Typically you will want to create the project first"
echo "- The install of tekton is optional. The tekton install allows setting up triggers and webhooks"
echo "- After setting up the namespace you will proceed to install mysql"
echo "- Next you install light-bc-inventory which will install the generic pipeline"
echo "- Next you return here to setup and run the pipeline to deploy the user interface"
echo "- Finally the database can be loaded"
echo "  Note: the light-bc-inventory service must have initialized and created the item table in the inventory database"

PS3='Please enter your choice: '
options=("delete namespace" "init namespace" "install mysql non-persistent" "install mysql persistent" "install tekton" "setup pipeline" "run pipeline" "load db" "Quit")
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

            echo "proceed to installing mysql"
            echo "NOTE: when you install mysql with persistent storage then you need a cluster that can honor persistent volume claim requests"

            break
            ;;
        "install mysql non-persistent")
            echo "install mysql without persistent storage, inserts will be lost on restart of mysql"
            oc apply -f mysql.yaml
            break
            ;;
        "install mysql persistent")
            echo "install mysql with persist storage, inserts will survice a restart of mysql"
            oc apply -f mysql-persistent.yaml
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
