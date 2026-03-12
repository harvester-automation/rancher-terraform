# Machine configuration for RKE2 nodes using Harvester node driver
resource "rancher2_machine_config_v2" "rke2-machine" {
  generate_name = "rke2-machine"
  harvester_config {
    vm_namespace = "vm-ns"
    cpu_count    = "4"
    memory_size  = "8"

    disk_info = <<-EOF
    {
      "disks": [{
        "imageName": "vm-ns/image-tth9v",
        "size": 100,
        "bootOrder": 1
      }]
    }
    EOF

    network_info = <<-EOF
    {
      "interfaces": [{
        "networkName": "vm-ns/service-vm-vlan"
      }]
    }
    EOF

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

    # Use DHCP4 for internal DNS resolution (required for sslip.io)
    # Disable DHCP routes to avoid duplicate default routes
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
  name = "rke2-terraform"

  # v1.34.3 fixes tigera-operator ClusterIP access issue in v1.28
  kubernetes_version = "v1.34.3+rke2r1"

  timeouts {
    create = "90m"
    update = "45m"
    delete = "45m"
  }

  rke_config {
    machine_pools {
      name                         = "pool1"
      cloud_credential_secret_name = local.cloud_credential_secret_name
      control_plane_role           = true
      etcd_role                    = true
      worker_role                  = true
      quantity                     = 1
      machine_config {
        kind = rancher2_machine_config_v2.rke2-machine.kind
        name = rancher2_machine_config_v2.rke2-machine.name
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
