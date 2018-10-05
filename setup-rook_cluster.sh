# Clonando repositorios Git
#echo -e "\u001b[32mClone the Git Repository\u001b[m\r\n"
#git clone https://github.com/rook/rook.git
#git clone https://github.com/erickeliseo/files.git

# Cambiando permisos al setup.sh
#chmod u+x files/setup-rook_cluster.sh

export FILESPATH=~/files/
export ROOTCEPHPATH=~/rook/cluster/examples/kubernetes/ceph
export ROOTCEPHMONPATH=~/rook/cluster/examples/kubernetes/monitoring
# Instalando Rook y Habilitando el Monitoreo
echo -e "\u001b[32mWait for Kubernetes and Rook to be ready\u001b[m\r\n"
kubectl create -f ~/rook/cluster/examples/kubernetes/ceph/operator.yaml
sleep 15
kubectl create -f ~/rook/cluster/examples/kubernetes/ceph/cluster.yaml
sleep 15

# Instalando Prometheus
echo -e "\u001b[32mPrometheus\u001b[m\r\n"
kubectl create -f ~/files/dashboard-external-NodePort.yaml
sleep 15
kubectl create -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.15/bundle.yaml
sleep 15
kubectl create -f ~/rook/cluster/examples/kubernetes/monitoring/service-monitor.yaml
sleep 15
kubectl create -f ~/rook/cluster/examples/kubernetes/monitoring/prometheus.yaml
sleep 15
kubectl create -f ~/rook/cluster/examples/kubernetes/monitoring/prometheus-service.yaml
sleep 60
# Extraer configuracion de Prometheus e insertar en ~/files/grafana-helm-values.yaml
export URL=http://"$(kubectl -n rook-ceph -o jsonpath={.status.hostIP} get pod prometheus-rook-prometheus-0):9090"
sed -i "s|url:|url: $URL|g" ~/files/grafana-helm-values.yaml
sleep 5
## Instalando Grafana
echo -e "\u001b[32mGrafana\u001b[m\r\n"
kubectl create -f ~/files/grafana-external-NodePort.yaml
helm install --name grafana-rook-cluster stable/grafana -f ~/files/grafana-helm-values.yaml
sleep 150
# Extraer POD y URL de Grafana
export PODGRAFANA=$(kubectl get pods | grep grafana-rook-cluster | awk '{print $1}')
export URLGRAFANA=http://"$(kubectl  -o jsonpath={.status.hostIP} get pod "$(kubectl get pods | grep grafana-rook-cluster | awk '{print $1}')")":3000

# Instalando Dashboard de Rook en Grafana
# Descarga el JSON del Dashboard 2842
kubectl exec -it $PODGRAFANA  curl https://grafana.com/api/dashboards/2842/revisions/7/download > /tmp/grafana-dashboard-Ceph-Cluster-2842.json

# Elimina la primera linea /tmp/grafana-dashboard-Ceph-Cluster-2842.json
kubectl exec -it $PODGRAFANA sed -i '1d' /tmp/grafana-dashboard-Ceph-Cluster-2842.json

# Inserta linea /tmp/grafana-dashboard-Ceph-Cluster-2842.json
kubectl exec -it $PODGRAFANA sed -i '1i "dashboard": {' /tmp/grafana-dashboard-Ceph-Cluster-2842.json

# Inserta linea /tmp/grafana-dashboard-Ceph-Cluster-2842.json
kubectl exec -it $PODGRAFANA sed -i '1i {' /tmp/grafana-dashboard-Ceph-Cluster-2842.json

# Inserta linea /tmp/grafana-dashboard-Ceph-Cluster-2842.json
kubectl exec -it $PODGRAFANA echo "}" >> /tmp/grafana-dashboard-Ceph-Cluster-2842.json
