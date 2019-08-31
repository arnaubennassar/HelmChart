# Set up K8S Cluster

## Install OS and dependencies

### Atomic Pi (Ubuntu Server)
1. Download last ubuntu server image
2. Flash and boot, follow graphic installer
3. SSH into the machine
4. Install docker, kubeadm, kubelet and kubectl. `sudo apt-get update -y && sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && sudo apt-get update && sudo apt-get install docker-ce -y && sudo systemctl enable docker && sudo systemctl restart docker && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl docker-ce`
5. Disable swap: `sudo swapoff -a && sudo nano /etc/fstab`: comment the swap line
6. Install gluster client (NOT IN THE MASTER NODE): `sudo add-apt-repository ppa:gluster/glusterfs-6 -y && sudo apt-get update -y && sudo apt-get install glusterfs-client -y`
7. Change password: `passwd`

### Pi 4 (Raspbian Buster lite)
1. Download last Raspbian lite [image](https://www.raspberrypi.org/downloads/raspbian/)
2. Flash, when its done enable ssh: create a empty file named ssh on the root of boot partition
3. SSH into the machine
4. Install docker, kubeadm, kubelet and kubectl. ***WARNING: this script uses a hack to install docker for raspbian stretch since it's not available yet for buster*** `sudo apt-get update -y && sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y && curl -sL get.docker.com | sed 's/9)/10)/' | sh && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl docker-ce`
5. Disable swap: `sudo dphys-swapfile swapoff && sudo dphys-swapfile uninstall && sudo systemctl disable dphys-swapfile`
6. Install gluster client (NOT IN THE MASTER NODE) ***WARNING: this will install an outdated version of gluster client***: `sudo apt-get install glusterfs-client -y`
7. Change password: `passwd`
8. Change hostname: `sudo nano /etc/hostname`
9. Reboot: `sudo reboot`

### Rock64 (Ubuntu Minimal Containers)
1. Download and flash latest Ubuntu Minimal Containers [image](https://wiki.pine64.org/index.php/ROCK64_Software_Release)
2. Connect to Rock64 via SSH (rock64 - rock64)
3. Change password
4. Install gluster client (NOT IN THE MASTER NODE): `sudo add-apt-repository ppa:gluster/glusterfs-6 -y && sudo apt-get update -y && sudo apt-get install glusterfs-client -y`
5. Change password: `passwd`
6. Change hostname: `sudo nano /etc/hostname`
7. Reboot: `sudo reboot`

## K8S configuration

### Set up single master with flannel network, join nodes
0. Connect via ssh to the node you want to be the master
1. Init kubernetes (specific config for flannel): `sudo sysctl net.bridge.bridge-nf-call-iptables=1 && sudo kubeadm init --pod-network-cidr=10.244.0.0/16`.
2. When it's done it will print a commands that you must apply, they will look like: ```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config```
3. Deploy Flannel: `kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`
4. The second command will also print a message that you must copy to use it later for joining nodes, looks like (you can get a new token by running `kubeadm token create`): ```
kubeadm join 192.168.1.10:6443 --token ewpf1s.hinx1g1wei5wchw3 \
    --discovery-token-ca-cert-hash sha256:a2049c0467b8742d34de96d1c43a27b9417c32d514eb3a5584b613a83f64bcf0```
5. Paste that command on all the non master nodes (connect to them via ssh).
6. Check that nodes have joined: `kubectl get nodes`
7. Check that network is working: `kubectl get pods --all-namespaces` (CoreDNS should be running, may take some time)

### Rancher (only one node)
0. Connect via ssh to the node you want to be the rancher server. Cannot be the node where the LB (traefik, nginx, ...) is deployed as it will require the 80 & 443 port.
1. Run rancher: `sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher`
2. Browse to the node IP and login into the Web UI. Add existing cluster.

### Labels
1. Add labels to be able to chose in which nodes pods will run: `kubectl label nodes <node-name> <label-key>=<label-value>`

# GlusterFS

## Install Ubuntu Minimal (on each node)
1. Download and flash the image
2. Plug SD Card on SBC
2. MANUALY REBOOT AFTER A WHILE?
3. Connect via SSH (root - odroid) and follow the installer
4. Update the system `sudo apt-get update -y` then `sudo apt-get upgrade -y && sudo apt dist-upgrade -y`

## Set up GlusterFS (on each node)
1. Add gluster community repo and install: `sudo apt-get install software-properties-common -y && sudo add-apt-repository ppa:gluster/glusterfs-6 -y && sudo apt-get update -y && sudo apt-get install glusterfs-server -y`
2. Create trusted pool, from one node to the others: `gluster peer probe data-one && gluster peer probe data-two` ...
3. Check that all nodes are listed: `gluster pool list`

## Topology
Replicated volume with two bricks over three nodes with an arbiter:

data-zero: 1T ==D 4G (arbi1) "1T" (brick0)
data-zero: 3T ==D 4G (arbi0) "3T" (brick1)
data-zero: 4T ==D 1T (brick0) 3T (brick1)

1. On each node format the disks as described on the topology: `sudo fdisk /dev/sda`. If disk is larger than 2T, use option g.
2. Create folders where the disks will be mounted according to the toppology (/glu/(name)
3. Find UUIDs of partitions: `sudo blkid /dev/sdaX`
4. Edit fstab `sudo nano /etct/fstab`: `
...
UUID=XXXXX..... /glu/(name) ext4 defaults,noatime,rw 0 0
PARTUUID=a3669dba-f747-4a41-a42f-441df54d7f3a /glu/brick0 ext4 defaults 0 0
PARTUUID=4ebf2968-9b24-41ce-960d-ca381ceb3764 /glu/brick1 ext4 defaults 0 0
`
5. Create filesystem on each partition: `sudo mkfs.ext4 /dev/sdX`
6. Check that it works: `sudo mount -a`
7. Create the gluster volume according to the topology (from any node): `gluster volume create gluVol replica 3 arbiter 1 \
192.168.1.20:/glu/brick0 \
192.168.1.22:/glu/brick0 \
192.168.1.21:/glu/arbi0 \
192.168.1.21:/glu/brick1 \
192.168.1.22:/glu/brick1 \
192.168.1.20:/glu/arbi1 \
force
`
8. Start the volume: `gluster volume start  gluVol`
9. Check result: `gluster volume info`
10. Mount on a client (gluster-client must be installed): `sudo mount -t glusterfs data-zero:/gluVol /home/bro/gluVol/`

## Restore node (disk still OK, reinstall OS)
1. Follow "Install Ubuntu Minimal (on each node)"
2. Edit fstab with the still OK disk and according to the previous toppolgy
3. Get the UUID: from one of the running nodes: `gluster peer status` and copy it.
4. Replace UUID by the paste and run: `sudo systemctl stop glusterd.service && UUID=c8f3c5fe-7753-4351-9fb5-7270f103836c && sed  -i "s/\(UUID\)=\(.*\)/\1=$UUID/g" /var/lib/glusterd/glusterd.info && sudo systemctl restart glusterd.service`
5. Add the peers again: `gluster peer probe data-zero && gluster peer probe data-one` ...
6. Restart daemon again: `sudo systemctl restart glusterd.service`
7. Check it: `gluster volume status`
8. [if shit happens...](https://support.rackspace.com/how-to/recover-from-a-failed-server-in-a-glusterfs-array/)
