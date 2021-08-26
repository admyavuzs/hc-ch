# Cookiecutter/Boilerplate

## Google GKE and SQL with terraform

## Initial tooling setup gcloud, kubectl and terraform

Assuming you already have Google Cloud account we will need additional binaries for gcloud CLI,, terraform and kubectl.
Gcloud deployment differs from Linux distribution and you can follow the [link](https://cloud.google.com/sdk/docs/quickstarts) to deploy for OSX and diff Linux distributions

### Deploying terraform

#### Installation cli

```sh
See https://learn.hashicorp.com/tutorials/terraform/install-cli
```

#### Verification

Verify terraform version 0.11.10 or higher is installed:

```sh
terraform version
```

### Deploying kubectl

#### Installation cli

```sh
See https://kubernetes.io/docs/tasks/tools/
```

#### Verification

```sh
kubectl version --client
```

### Authenticate to gcloud

Before configuring gcloud CLI you can check available Zones and Regions nearest to your location

```sh
gcloud compute regions list

gcloud compute zones list
```

Follow gcloud init and select default Zone Ex. asia-south1

```sh
gcloud init
```

## Creating Google Cloud project and service account for terraform

Best practice to use separate account "technical account" to manage infrastructure

### Set up environment

```sh
export TF_CREDS=config/gcloud/infra-admin-307815-f82260f31a8c.json
export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}
export GOOGLE_PROJECT=infra-admin-307815
```

### Create the Terraform Admin Project

Create a new project (name: infra-admin, id: infra-admin-307815 ) and link it to your billing account 

### Create the Terraform service account

Create the service account in the Infra admin project and download the JSON credentials.

Assign owner role

Enabled API for newly created projects

```sh
gcloud services enable cloudresourcemanager.googleapis.com && \
gcloud services enable cloudbilling.googleapis.com && \
gcloud services enable iam.googleapis.com && \
gcloud services enable compute.googleapis.com && \
gcloud services enable sqladmin.googleapis.com && \
gcloud services enable container.googleapis.com
```

## Creating back-end storage to tfstate file in Cloud Storage

Terraform stores the state about infrastructure and configuration by default local file "terraform.tfstate. State is used by Terraform to map resources to configuration, track metadata.

Terraform allows state file to be stored remotely, which works better in a team environment or automated deployments.
We will used Google Storage and create new bucket where we can store state files.

Create the remote back-end bucket in Cloud Storage for storage of the terraform.tfstate file

```sh
export TF_ADMIN_ID = infra-admin-307815
gcloud config set project infra-admin-307815
gsutil mb -p ${INFRA_ADMIN_ID} -l us-central1 gs://${INFRA_ADMIN_ID}
```

Enable versioning for said remote bucket:

```sh
gsutil versioning set on gs://${INFRA_ADMIN_ID}
```

Configure your environment for the Google Cloud terraform provider

```sh
export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}
```

## Setting up separate projects for Development and Production environments

In order to segregate Development environment we will use Google cloud projects that allows us to segregate infrastructure bur maintain same time same code base for terraform.

Terraform allow us to use separate tfstate file for different environment by using terraform functionality workspaces.
Let's see current file structure

```sh
.
├── backend.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars
└── variables.tf
```

### Initialize and pull terraform cloud specific dependencies

Terraform uses modular setup and in order to download specific plugin for cloud provider, terraform will need to be 1st initiated.

```sh
terraform init
```

### Workspace creation for dev and prod

Once we have our project code and our tfvar secretes secure we can create workspaces for terraform

> NOTE: in below example we will use only dev workspace but you can use both following same logic

* Create dev workspace

```sh
terraform workspace new dev
```

* List available workspaces

```sh
terraform workspace list
```

* Switch between workspaces

```sh
terraform workspace select dev
```

### Terraform plan

Terraform plan will simulate what changes terraform will be done on cloud provider

```sh
terraform plan
```

### Apply terraform plan for selected environment

```sh
terraform apply
```

## Creating Kubernetes cluster on GKE and PostgreSQL on Cloud SQL

Once we have project ready for dev and prod we can move into deploying our gke and sql infrastructure.

Code structure

```sh
.
├── backend
│   ├── firewall
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── subnet
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc
│       ├── main.tf
│       └── outputs.tf
├── backend.tf
├── cloudsql
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── gke
│   ├── main.tf
│   ├── outputs.tf
│   ├── helm.tf
│   └── variables.tf
├── main.tf
├── outputs.tf
└── variables.tf
```

Now is time to deploy our infrastructure, noticeable differences between prod and dev workspaces you can find in the terraform files.

* dev - single instance of PostgreSQL without replication and read replica
* prod - single instance in multi AZ for high availablity and additional one read replica for PostgreSQL
* dev - single kubernetes node will be added to GKE
* prod - two nodes will be created and added to kubernetes GKE

> NOTE: Cluster autoscaling is disabled on default. If you are sure that you'll need it, uncommented cluster_autoscaling config on gke/main.tf

> NOTE: Horizantal pod autoscaler can be enabled withing helm charts deployments. Please refer to charts/healthcheck/templates/hpa.yaml and related configuration on values.yaml

### Running terraform changes for infrastructure

We are now ready to to run our plan and create infrastructure.

As we are in separate code base will need to follow same sequence as in project creation.

> NOTE: Just make sure you have new terraform.tfvars

```sh
bucket_name         = "infra-admin-307815"
gke_master_pass     = "your-gke-password"
sql_pass            = "your-sql-password"
```

* Initialize and pull terraform cloud specific dependencies

```sh
terraform init
```

* Create dev workspace

```sh
terraform workspace new dev
```

* List available workspaces

```sh
terraform workspace list
```

* Switch between workspaces

```sh
terraform workspace select dev
```

* Terraform plan will simulate what changes terraform will be done on cloud provider

```sh
terraform plan
```

* Apply terraform

```sh
terraform apply
```

* To check what terraform deployed use

```sh
terraform show
```

* Once test is completed you can remove "destroy" all buildup infrastructure.

```sh
terraform destroy -auto-approve
```

## Terraform Tips

* Refresh terraform

```sh
terraform refresh
```

* List and show terraform state file

```sh
terraform state list
terraform state show
```

* Destroy only selected module Ex.

```sh
terraform destroy -target=module.cloudsql
```
