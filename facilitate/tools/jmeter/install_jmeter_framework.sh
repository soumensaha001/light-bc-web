oc project tools

# Install influxdb
oc apply -f influxdb-data.yaml 
oc apply -f influxdb-secrets.yaml 
oc apply -f influxdb-config.yaml 
oc apply -f influxdb-deployment.yaml 
oc apply -f influxdb-service.yaml 

oc get packagemanifests -n openshift-marketplace | grep grafana

# Install Grafana
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-grafana-operator
  namespace: openshift-operators
spec:
  channel: alpha
  name: grafana-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF

# TODO: post yaml tp configure datasource

#dashboard 5496 JMeter for graphana.
#import <code>

# TODO:
# build and push the Dockerfile

# TODO:
# post yaml with JMeter tekton task

# Pipeline
 # post pipeline