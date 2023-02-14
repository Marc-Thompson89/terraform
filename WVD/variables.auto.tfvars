# Provider info
subscriptionID = "####"
clientID = "####"
clientSecret = "####"
tenantID = "####"

#Deployment
rg-host-pool  = "rg-host-pool"
sg-host-pool  = "sg-host-pool"
host_pool_sc  = "hostpoolsc"
environment_name = "dev-avd"
prefix        = "avd"
location     = "uksouth"

#Network
avd_address_space = "0.0.0.0/0" #Primary Network
avd_subnet_name  = "avd_subnet"
avd_subnet_prefix = "0.0.0.0/0" #vm subnet


#Session Host
admin_username   = "administrator"
admin_password   = "password1!" #make your own
host-pool-name   = "avd-host-pool"
workspace_name   = "avd-workspace"
rdsh_count       = "3"
avd_users        = ["",""] #these users will need to exist in AAD
aad_group_name   = "avd-users-group"