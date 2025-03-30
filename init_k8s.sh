#!/bin/bash

echo "💡 Kubernetes 클러스터 설치를 시작합니다..."

# 1. swap 비활성화 (Kubernetes 요구사항)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# 2. 기본 패키지 설치
apt update
apt install -y curl gpg apt-transport-https ca-certificates

# 3. containerd 설치 및 설정
apt install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# 4. Kubernetes APT 저장소 설정 (Ubuntu 24.04 대응)
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list

# 5. kubelet, kubeadm, kubectl 설치
apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 6. 클러스터 초기화 (flannel에 맞게 CIDR 지정)
kubeadm init --pod-network-cidr=10.244.0.0/16

# 7. kubectl 설정
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# 8. flannel 네트워크 설치
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# 9. nginx 테스트 앱 배포 (있을 경우)
if [ -f ./manifests/nginx-deployment.yaml ]; then
  kubectl apply -f ./manifests/nginx-deployment.yaml
fi

echo "✅ Kubernetes 마스터 노드 초기화 완료!"
