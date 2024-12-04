# Host project defining networking
locals {
  projects_prefix = join("-", [var.project_name_prefix, var.project_unique_id])
  host_project_id = "${local.projects_prefix}-host"
  svc_project_id  = "${local.projects_prefix}-service"
  zones           = ["${var.region}-c", "${var.region}-d"]
}


module "host-project" {
  source                         = "terraform-google-modules/project-factory/google"
  version                        = "14.5.0"
  billing_account                = var.billing_account
  org_id                         = var.org_id
  name                           = local.host_project_id
  enable_shared_vpc_host_project = true
  svpc_host_project_id           = ""
  activate_apis = [
    "servicenetworking.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "container.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
}

module "network" {
  source       = "terraform-google-modules/network/google"
  version      = "6.0.1"
  depends_on   = [module.host-project]
  project_id   = local.host_project_id
  network_name = "${local.host_project_id}-network"
  subnets = [
    {
      subnet_name               = "${local.host_project_id}-gke-sb"
      subnet_ip                 = "192.168.0.0/22" // 1022 nodes
      subnet_region             = var.region
      subnet_private_access     = var.subnet_private_access
      subnet_flow_logs          = var.subnet_flow_logs
      subnet_flow_logs_sampling = var.subnet_flow_logs_sampling
      subnet_flow_logs_metadata = var.subnet_flow_logs_metadata
      description               = "Subnet for the GKE nodes"
    },
  ]
  secondary_ranges = {
    "${local.host_project_id}-gke-sb" = [
      {
        range_name    = "${module.host-project.project_id}-gke-devops-pod-range"
        ip_cidr_range = "192.168.17.0/24" // 254 pods
      },
      {
        range_name    = "${module.host-project.project_id}-gke-devops-service-range"
        ip_cidr_range = "192.168.16.0/25" // 126 services
      },
    ],
  }
}

# # Service project hosting the GKE cluster

module "service-project" {
  source               = "terraform-google-modules/project-factory/google"
  version              = "14.5.0"
  depends_on           = [module.host-project, module.network]
  billing_account      = var.billing_account
  org_id               = var.org_id
  name                 = local.svc_project_id
  svpc_host_project_id = module.host-project.project_id
  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
}

module "kubernetes-engine_private-cluster" {
  source                      = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                     = "25.0.0"
  depends_on                  = [module.service-project]
  project_id                  = local.svc_project_id
  name                        = "gke-gpu-cluster"
  ip_range_pods               = module.network.subnets_secondary_ranges[0][0]["range_name"]
  ip_range_services           = module.network.subnets_secondary_ranges[0][1]["range_name"]
  master_ipv4_cidr_block      = "10.0.0.32/28"
  network_project_id          = module.host-project.project_id
  network                     = module.network.network_name
  subnetwork                  = module.network.subnets_names[0]
  regional                    = false
  zones                       = local.zones
  master_authorized_networks  = var.master_authorized_networks
  release_channel             = "STABLE"
  remove_default_node_pool    = true
  grant_registry_access       = true
  enable_binary_authorization = true
  enable_private_nodes        = true
  enable_shielded_nodes       = true

  node_pools = [
    {
      name               = "np-gpu-001"
      machine_type       = "n1-standard-4"
      node_locations     = join(",", local.zones)
      # Required when using STABLE channel
      auto_upgrade       = true
      initial_node_count = 0
      min_count          = 0
      max_count          = 3
      preemptible        = false
      local_ssd_count    = 0
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      accelerator_count  = 1
      accelerator_type   = "nvidia-tesla-t4"
      enable_secure_boot = true
    },
  ]
}
