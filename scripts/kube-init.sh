#!/bin/bash


HOME="/home/AzureUser"
  
sleep 5

echo "Initialising the Kubernetes:"
kubeadm init > /var/log/kubeadm-init.log
      
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown AzureUser:AzureUser $HOME/.kube/config
	   
tail -n 2 /var/log/kubeadm-init.log > /tmp/worker-init.sh
cat /tmp/worker-init.sh | awk 'BEGIN{print "#!/bin/bash \n"}{print}' > /usr/local/bin/worker-init.sh

sleep 2
echo -e "\n"

echo "Applying the CNI plugin: "
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

sleep 1m
echo -e "\n"
echo "Master Status......."
St_Master=`kubectl get nodes | tail -1 | awk '{print $1 " : " $2}'`
echo $St_Master

echo -e "\n"
echo "Join command......"

Join=`cat /usr/local/bin/worker-init.sh | tail -2`
# echo $Join

rm -rf /tmp/worker-init.sh

