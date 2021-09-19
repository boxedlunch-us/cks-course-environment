#!/bin/sh

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm/
sudo swapoff -a
sudo sed -i '/swap/s/^/#/g' /etc/fstab
### setup terminal
sudo apt-get update
sudo apt-get install -y bash-completion binutils
echo 'colorscheme ron' >> ~/.vimrc
echo 'set tabstop=2' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc


### install k8s and docker
sudo apt-get remove -y docker.io kubelet kubeadm kubectl kubernetes-cni
sudo apt-get autoremove -y
sudo apt-get install -y etcd-client vim build-essential

sudo systemctl daemon-reload
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
KUBE_VERSION=1.22.1
sudo apt-get update
sudo apt-get install -y docker.io kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00 kubernetes-cni=0.8.7-00

sudo cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "storage-driver": "overlay2"
}
EOF
sudo mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
sudo systemctl daemon-reload
sudo systemctl restart docker

# start docker on reboot
sudo systemctl enable docker

sudo docker info | grep -i "storage"
sudo docker info | grep -i "cgroup"

# add vsphere cloud provider
sudo cat <<EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS="--cloud-provider=external"
EOF

sudo systemctl daemon-reload
sudo systemctl enable kubelet && systemctl start kubelet

### init k8s
sudo rm /root/.kube/config
sudo kubeadm reset -f
sudo kubeadm init --kubernetes-version=${KUBE_VERSION} --ignore-preflight-errors=NumCPU --skip-token-print

mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo
echo "### COMMAND TO ADD A WORKER NODE ###"
sudo kubeadm token create --print-join-command --ttl 0
