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

echo "sleep for 120 seconds to give the operator time to install"

sleep 120
oc apply -f grafana.yaml

echo "sleep for 10 seconds"
sleep 10
oc apply -f grafana_ds.yaml

echo "sleep for 10 seconds"
sleep 10
oc apply -f jmeter_dashboard.yaml

echo "sleep for 10 seconds"
sleep 10
oc expose svc grafana-operator-metrics