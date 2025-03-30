#!/bin/bash

echo "💡 Kubernetes 클러스터 설치를 시작합니다..."

# 1. swap off
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# 2. 필요한 패키지 설치
apt update -y
apt install -y apt-transport-https ca-certificates curl

# 3. Docker 대신 containerd 설치
apt install -y containerd
containerd config default | sudo tee /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# 4. Kubernetes 패키지 설치
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt update -y
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 5. 클러스터 초기화
kubeadm init --pod-network-cidr=10.244.0.0/16

# 6. kubectl config 설정
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# 7. 네트워크 플러그인(flannel) 설치
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "✅ Kubernetes 마스터 노드 초기화 완료"
