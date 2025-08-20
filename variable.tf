# variable.tf

variable "cluster_name" {
    description = "The name of the DOKS cluseter"
    type = string
    default = "learning-cluster"
}

variable "region_name" {
    description = "The aws region for the cluster"
    type = string
    default = "ap-south-1"
}

variable "instance_type" {
    description = "The aws machine used"
    type = string
    default = "t2.micro"
}