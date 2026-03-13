# Machine configuration for control plane nodes
resource "rancher2_machine_config_v2" "control-plane" {
  generate_name = "control-plane"
  harvester_config {
    vm_namespace = var.vm_namespace
    cpu_count    = var.control_plane_vm_spec.cpu_count
    memory_size  = var.control_plane_vm_spec.memory_size

    disk_info = jsonencode({
      disks = [{
        imageName = var.vm_image_name
        size      = var.control_plane_vm_spec.disk_size
        bootOrder = 1
      }]
    })

    network_info = jsonencode({
      interfaces = [{
        networkName = var.vm_network_name
      }]
    })

    ssh_user = "ubuntu"

    user_data = <<-EOF
    #cloud-config
    password: ubuntu
    chpasswd:
      expire: false
    ssh_pwauth: true
    package_update: true
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable --now qemu-guest-agent
    EOF

    network_data = <<-EOF
    version: 2
    ethernets:
      enp1s0:
        dhcp4: true
        dhcp4-overrides:
          use-routes: false
        routes:
          - to: default
            via: 10.161.96.1
        nameservers:
          addresses:
            - 8.8.8.8
            - 8.8.4.4
    EOF
  }
}

# Machine configuration for worker nodes
resource "rancher2_machine_config_v2" "worker" {
  count          = var.worker_count > 0 ? 1 : 0
  generate_name  = "worker"
  harvester_config {
    vm_namespace = var.vm_namespace
    cpu_count    = var.worker_vm_spec.cpu_count
    memory_size  = var.worker_vm_spec.memory_size

    disk_info = jsonencode({
      disks = [{
        imageName = var.vm_image_name
        size      = var.worker_vm_spec.disk_size
        bootOrder = 1
      }]
    })

    network_info = jsonencode({
      interfaces = [{
        networkName = var.vm_network_name
      }]
    })

    ssh_user = "ubuntu"

    user_data = <<-EOF
    #cloud-config
    password: ubuntu
    chpasswd:
      expire: false
    ssh_pwauth: true
    package_update: true
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable --now qemu-guest-agent
    EOF

    network_data = <<-EOF
    version: 2
    ethernets:
      enp1s0:
        dhcp4: true
        dhcp4-overrides:
          use-routes: false
        routes:
          - to: default
            via: 10.161.96.1
        nameservers:
          addresses:
            - 8.8.8.8
            - 8.8.4.4
    EOF
  }
}

resource "rancher2_cluster_v2" "rke2-demo" {
  name = var.cluster_name

  # v1.34.3 fixes tigera-operator ClusterIP access issue in v1.28
  kubernetes_version = "v1.34.3+rke2r1"

  timeouts {
    create = "180m"
    update = "45m"
    delete = "45m"
  }

  rke_config {
    # Control plane pool
    machine_pools {
      name                         = "control-plane"
      cloud_credential_secret_name = local.cloud_credential_secret_name
      control_plane_role           = true
      etcd_role                    = true
      worker_role                  = false
      quantity                     = var.control_plane_count
      machine_config {
        kind = rancher2_machine_config_v2.control-plane.kind
        name = rancher2_machine_config_v2.control-plane.name
      }
    }

    # Worker pool
    dynamic "machine_pools" {
      for_each = var.worker_count > 0 ? [1] : []
      content {
        name                         = "worker"
        cloud_credential_secret_name = local.cloud_credential_secret_name
        control_plane_role           = false
        etcd_role                    = false
        worker_role                  = true
        quantity                     = var.worker_count
        machine_config {
          kind = rancher2_machine_config_v2.worker[0].kind
          name = rancher2_machine_config_v2.worker[0].name
        }
      }
    }

    machine_global_config = <<-EOF
    cni: calico
    EOF

    # Use VXLAN encapsulation instead of IPIP for Harvester virtual networks
    # IPIP (protocol 4) is blocked in Harvester overlay networks
    chart_values = <<-EOF
    rke2-calico:
      installation:
        calicoNetwork:
          bgp: Disabled
          ipPools:
            - cidr: 10.42.0.0/16
              encapsulation: VXLAN
              natOutgoing: Enabled
              nodeSelector: all()
    EOF

    upgrade_strategy {
      control_plane_drain_options {
        enabled = false
      }
      worker_drain_options {
        enabled = false
      }
      control_plane_concurrency = "10%"
      worker_concurrency        = "10%"
    }
  }
}
