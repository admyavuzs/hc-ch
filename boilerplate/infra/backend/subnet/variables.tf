# Subnet variables

variable "region" {
  description = "Region of resources"
}

variable "vpc_name" {
  description = "Network name"
}

variable "subnet_cidr" {
  type        = "map"
  description = "Subnet range"
}
