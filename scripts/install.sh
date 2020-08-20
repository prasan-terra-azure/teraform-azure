#!/bin/bash

apt update -y
apt install -y docker.io
apt install -y apt-transport-https

systemctl restart docker
systemctl enable docker

sleep 3

sudo usermod -aG docker AzureUser

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list 
deb https://apt.kubernetes.io/ kubernetes-xenial main 
EOF

apt update -y
apt-get install -y kubelet kubeadm kubectl && apt-mark hold kubelet kubeadm kubectl

echo "Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=cgroupfs"" >> kubeadm.conf

cat kubeadm.conf >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload 

systemctl restart kubelet
