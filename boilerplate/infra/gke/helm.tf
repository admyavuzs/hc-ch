variable "helm_version" {
  default = "v3.5.2"
}

data "google_client_config" "current" {}

provider "helm" {

  kubernetes {
    host                   = "${google_container_cluster.primary.endpoint}"
    token                  = "${data.google_client_config.current.access_token}"

    client_certificate     = "${base64decode(google_container_cluster.primary.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(google_container_cluster.primary.master_auth.0.client_key)}"
    cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
  }
}

#kube-prometheus-stack helm chart deployment
resource "helm_release" "kube-prometheus-stack" {
  name  = "kube-prometheus-stack"
  chart = "./charts/kube-prometheus-stack"

  values = [<<EOF
rbac:
  create: false
controller:
  stats:
    enabled: true
  metrics:
    enabled: true
  service:
    annotations:
    externalTrafficPolicy: "Local"
EOF
  ]

  depends_on = [
    "google_container_cluster.primary",
    "helm_release.nginx-ingress"
    "helm_release.vault"
  ]
}

#vault helm chart deployment
resource "helm_release" "vault" {
  name  = "vault"
  namespace = "healthcheck"
  create_namespace = "true"
  chart = "./charts/vault"

  depends_on = [
    "google_container_cluster.primary",
  ]
}

#vault helm chart deployment
resource "helm_release" "nginx-ingress" {
  name  = "nginx-ingress"
  namespace = "nginx-ingress"
  create_namespace = "true"
  chart = "./charts/nginx-ingress"

  depends_on = [
    "google_container_cluster.primary",
  ]
}