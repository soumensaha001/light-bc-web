oc project tools

# Install influxdb
oc apply -f influxdb/influxdb-data.yaml 
oc apply -f influxdb/influxdb-secrets.yaml 
oc apply -f influxdb/influxdb-config.yaml 
oc apply -f influxdb/influxdb-deployment.yaml 
oc apply -f influxdb/influxdb-service.yaml 

oc get packagemanifests -n openshift-marketplace | grep grafana

oc apply -f operator-group.yaml

# Install Grafana
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-grafana-operator
  namespace: tools
spec:
  channel: alpha
  name: grafana-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF

sleep 120

# TODO: post yaml tp configure datasource
oc apply -f grafana.yaml

sleep 10
oc apply -f grafana_ds.yaml

sleep 10
oc apply -f jmeter_dashboard.yaml

sleep 10
oc expose svc grafana-operator-metrics

#dashboard 5496 JMeter for graphana.
#import <code>

# TODO:
# build and push the Dockerfile

# TODO:
# post yaml with JMeter tekton task

# Pipeline
 # post pipeline
