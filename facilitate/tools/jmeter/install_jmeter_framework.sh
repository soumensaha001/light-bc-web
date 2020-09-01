oc project tools

oc apply -f influxdb-data.yaml 
oc apply -f influxdb-secrets.yaml 
oc apply -f influxdb-config.yaml 
oc apply -f influxdb-deployment.yaml 
oc apply -f influxdb-service.yaml 

#TODO:
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators
spec:
  channel: ocp-4.4
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# TODO

# post yaml
# configure datasource

#dashboard 5496 JMeter for graphana.
#import <code>

# TODO:
# build and push the Dockerfile

# TODO:
# post yaml with JMeter tekton task

# Pipeline
 # post pipeline