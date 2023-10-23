#!/bin/bash

# Comprobar si se han proporcionado los argumentos requeridos
if [ $# -ne 3 ]; then
  echo "Uso: $0 nombre tamaño_vol red"
  exit 1
fi

nombre_maquina=$1
tamano_volumen=$2
red_intra=$3

# Nombre del puente
puente=$(virsh --connect qemu:///system net-dumpxml "${red_intra}" | grep -m 1 -oP "<bridge name='\K[^']+")

# Creacion de un nuevo volumen a partir de la plantilla
virsh --connect qemu:///system vol-create-as default "${nombre_maquina}.qcow2" "${tamano_volumen}G" --format qcow2 --backing-vol "/var/lib/libvirt/images/practica1.qcow2" --backing-vol-format qcow2

# Cambiar el nombre del host de la máquina virtual
sudo virt-customize -v -x --connect "qemu:///system" -a "/var/lib/libvirt/images/${nombre}.qcow2" --hostname "${nombre_maquina}"

# Redimensionar volumen y la instalación de la máquina virtual
cp "/var/lib/libvirt/images/${nombre_maquina}.qcow2" "/var/lib/libvirt/images/new${nombre_maquina}.qcow2"
virt-resize --expand /dev/sda1 "/var/lib/libvirt/images/new${nombre_maquina}.qcow2" "/var/lib/libvirt/images/${nombre_maquina}.qcow2"
virt-install --connect qemu:///system --noautoconsole --virt-type kvm --name "${nombre_maquina}" --os-variant debian10  --disk path="/var/lib/libvirt/images/${nombre}.qcow2",size="${tamano_volumen}",format=qcow2 --memory 4096 --vcpus 2 --import --network bridge="${puente}"

# Iniciar la máquina virtual
virsh --connect qemu:///system start "${nombre_maquina}"

