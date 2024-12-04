# gke-gpu-example

This repository creates a private GKE cluster in your organization within a [Shared VPC setup](https://cloud.google.com/vpc/docs/shared-vpc).

## Setup

Make sure you have the right permissions to create the needed resources:

* roles/resourcemanager.projectCreator: Create projects.
* roles/compute.admin: Network and compute resources.
* roles/container.admin: Kubernetes resources.

> ‼️ The above list is non exhaustive

Create the `terraform.tfvars` file by copying the `terraform.tfvars.example` file. Adjust it to your organization parameters. 

### Required variables

* `billing_account`: The billing account ID to which the resources will be associated to.
* `org_id`: Your GCP org ID.
* `project_unique_id`: A random string to prevent project name collisions. You can manually type or auto generate. Only needed every time you want to create the setup on a clean project.
* `master_authorized_networks`: CIDR ranges of allowed ranges that can connect to the cluster.

## Provision resources

Run the following command to create all resources.

```
terraform apply
```
