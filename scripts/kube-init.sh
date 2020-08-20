#!/bin/bash


HOME="/home/AzureUser"
  
   
kubeadm init > /var/log/kubeadm-init.log
      
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown AzureUser:AzureUser $HOME/.kube/config
	   
tail -n 2 /var/log/kubeadm-init.log > /tmp/worker-init.sh
cat /tmp/worker-init.sh | awk 'BEGIN{print "#!/bin/bash \n"}{print}' > /usr/local/bin/worker-init.sh
   
rm -rf /tmp/worker-init.sh

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

knds=`kubectl get nodes`

echo $knds
