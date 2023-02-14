#Azure Provider info
variable subscriptionID {}
variable clientID {}
variable clientSecret {}
variable tenantID {}

#Deployment
variable "rg-host-pool" {}
variable "sg-host-pool"{}
variable "host_pool_sc" {}
variable "environment_name" {}
variable "prefix" {}
variable "location"{}


#Network
variable "avd_address_space"{}
variable "avd_subnet_name"{}
variable "avd_subnet_prefix" {}

#Session Host
variable "admin_username" {}
variable "admin_password" {}
variable "host-pool-name" {}
variable "workspace_name" {}
variable "rdsh_count" {}
variable "avd_users" {}
variable "aad_group_name" {}