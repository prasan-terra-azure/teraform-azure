variable "location" {}

variable "admin_username" {
    type = string
    description = "Administrator user name for virtual machine"
}

variable "admin_password" {
    type = string
    description = "Password must meet Azure complexity requirements"
}

variable "prefix" {
    type = string
    default = "K8s-"
}

variable "tags" {
    type = map
    default = {
       Name = "Terra-K8s-Training"
    }
}

variable "sku" {
    default = {
        eastus = "18.04-LTS"
        westus2 = "16.04-LTS"
    }
}