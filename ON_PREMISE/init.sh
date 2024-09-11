#!/bin/bash
######################### default setting ###################################
echo "alias vi=vim " >> /etc/bashrc
echo "alias ll='ls -lh'" >> /etc/bashrc
source /etc/bashrc

echo "HISTSIZE=10000" >> /etc/profile
echo "HISTTIMEFORMAT='[%Y-%m-%d_%H:%M:%S] : '" >> /etc/profile

mv /etc/security/limits.conf /etc/security/limits_BAK

cat <<EOF > /etc/security/limits.conf
############### file, process limit ##############
* soft nofile 65535
* hard nofile 65535
* soft nproc unlimited
* hard nproc unlimited
EOF

###################### packages setting ######################################
systemctl disable --now firewalld
yum -y remove firewalld
yum -y install epel-release
yum -y install \
'htop' 'iftop' 'iotop' 'dstat' 'wget' 'net-tools' \
'sysstat' 'psmisc' 'lsof' 'iptables-services' 'ethtool' 'vim' 'python3.12' 'python3-pip' 'chrony' 'dnf-utils' 'unzip' 'rsyslog'

######################### SELINUX OFF ########################################
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

######################### server time setting ################################
mv /etc/chrony.conf /etc/chrony_BAK

cat <<EOF > /etc/chrony.conf
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
pool 2.rocky.pool.ntp.org iburst
EOF
timedatectl set-timezone Asia/Seoul

######################### iptables setting ###################################
mv /etc/sysconfig/iptables /etc/sysconfig/iptables_BAK

cat <<EOF > /etc/sysconfig/iptables
# sample configuration for iptables service
# you can edit this manually or use system-config-firewall
# please do not ask us to add additional ports/services to this default configuration
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF


######################### AWS-CLI setting ###################################
cd /usr/local/src
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
/usr/local/src/aws/install

######################### Terraform setting ###################################
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform


######################### k8s setting ###################################

### default Setting
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF > /etc/sysctl.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl -p

### containerd Install
cd /usr/local/src && wget https://github.com/containerd/containerd/releases/download/v1.7.22/containerd-1.7.22-linux-amd64.tar.gz
tar Cxzvf /usr/local/ containerd-1.7.22-linux-amd64.tar.gz

### Systemd Setting
cat <<EOF > /usr/lib/systemd/system/containerd.service
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

### Containerd Cgroup Setting
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml



### runc Install
cd /usr/local/src
wget https://github.com/opencontainers/runc/releases/download/v1.1.14/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

### Cni Plugin Install
wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.1.tgz


### kubelet kubeadm kubectl Install
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes


### calico Install
#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

systemctl enable --now chronyd sysstat iptables containerd kubelet
chronyc -a makestep
yum -y update

############ Restart Server ############
echo -n "Now Will be Restart!!! .... 5"
sleep 1
echo -ne "\rNow Will be Restart!!! .... 4"
sleep 1
echo -ne "\rNow Will be Restart!!! .... 3"
sleep 1
echo -ne "\rNow Will be Restart!!! .... 2"
sleep 1
echo -ne "\rNow Will be Restart!!! .... 1"
sleep 1
echo

reboot
