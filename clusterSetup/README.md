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

### Pi 4 (Ubuntu Server 64bits) *This image is unofficial, upgrade to official when released!*
1. Download latest image [here](https://jamesachambers.com/raspberry-pi-ubuntu-server-18-04-2-installation-guide/)
2. Flash
3. SSH into the machine (can take a while, ubuntu - ubuntu)
4. Change hostname: `sudo nano /etc/hostname`
5. Create new user *Replace <node-name>!!!*: `sudo useradd worker-four && sudo passwd worker-four`. Add the user to the sudoers `sudo adduser worker-four sudo`. Exit and login with the new user.
6. Delete old user: `sudo userdel -r -f ubuntu`
7. Disable swap: `sudo swapoff -a`: comment the swap line
8. Install gluster client, docker, kubeadm, kubelet and kubectl. `sudo add-apt-repository ppa:gluster/glusterfs-6 -y && sudo apt-get update -y && sudo apt-get install apt-transport-https ca-certificates curl software-properties-common glusterfs-client -y && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && sudo apt-get update && sudo apt-get install docker-ce -y && sudo systemctl enable docker && sudo systemctl restart docker && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl docker-ce`
9. Reboot: `sudo reboot`

### Rock64 (Ubuntu Minimal Containers)
1. Download and flash latest Ubuntu Minimal Containers [image](https://wiki.pine64.org/index.php/ROCK64_Software_Release)
2. Connect to Rock64 via SSH (rock64 - rock64)
3. Change password
4. Change hostname: `sudo nano /etc/hostname`
5. Create new user *Replace <node-name>!!!*: `sudo useradd worker-five && sudo passwd worker-five`. Add the user to the sudoers `sudo adduser worker-five sudo`. Exit and login with the new user.
6. Delete old user: `sudo userdel -r -f rock64`
7. Install gluster client (NOT IN THE MASTER NODE): `sudo add-apt-repository ppa:gluster/glusterfs-6 -y && sudo apt-get update -y && sudo apt-get install glusterfs-client -y`
8. Reboot: `sudo reboot`

## K8S configuration

### Set up single master with flannel network, join nodes
0. Connect via ssh to the node you want to be the master
1. Init kubernetes (specific config for flannel): `sudo sysctl net.bridge.bridge-nf-call-iptables=1 && sudo kubeadm init --pod-network-cidr=10.244.0.0/16`.
2. When it's done it will print a commands that you must apply, they will look like: ```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config```
3. Deploy Flannel: `kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`. *Required by Raspberrys?:* `kubectl patch daemonset kube-flannel-ds-arm \
      --namespace=kube-system \
      --patch='{"spec":{"template":{"spec":{"tolerations":[{"key": "node-role.kubernetes.io/master", "operator": "Exists", "effect":
      "NoSchedule"},{"effect":"NoSchedule","operator":"Exists"}]}}}}'`
4. The second command will also print a message that you must copy to use it later for joining nodes, looks like (you can get a new token by running `kubeadm token create`): ```
kubeadm join 192.168.1.10:6443 --token ewpf1s.hinx1g1wei5wchw3 \
    --discovery-token-ca-cert-hash sha256:a2049c0467b8742d34de96d1c43a27b9417c32d514eb3a5584b613a83f64bcf0```

### Join node
1. SSH into the nodes (all except the master) and run (Change IP of the master node and token): `sudo kubeadm join 192.168.1.10:6443 --token swj3k8.gik2hr3iapoweo11 --discovery-token-unsafe-skip-ca-verification`

### Rancher (only one node)
0. Connect via ssh to the node you want to be the rancher server. Cannot be the node where the LB (traefik, nginx, ...) is deployed as it will require the 80 & 443 port.
1. Run rancher: `sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher`
2. Browse to the node IP and login into the Web UI. Add existing cluster.
3. To access it remotely: `ssh -f user@ssh.server.com -L 6443:rancher.host.ip:443 -N`. Then in your browser: https://localhost:6443

### Labels
1. Add labels to be able to chose in which nodes pods will run: `kubectl label nodes <node-name> <label-key>=<label-value>`

## Remove a node
1. *Replace <node-name>!!!*: `kubectl drain worker-three --ignore-daemonsets --delete-local-data && kubectl delete node worker-three`

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
