#################################################
## Create Network
#################################################
resource "azurerm_virtual_network" "avd-net" {
  name                = "${var.environment_name}-net"
  address_space       = ["${var.avd_address_space}"]
  location            = var.location
  resource_group_name = var.rg-host-pool
  depends_on = [
    azurerm_resource_group.rg-host-pool
  ]
}

#Create AVD Subnet
resource "azurerm_subnet" "avd_subnet" {
  name                 = var.avd_subnet_name
  resource_group_name  = var.rg-host-pool
  virtual_network_name = "${azurerm_virtual_network.avd-net.name}"
  address_prefixes       = ["${var.avd_subnet_prefix}"]
}

# AVD Session host virtual nics
resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.rdsh_count
  name                = "${var.prefix}-${count.index + 1}-nic"
  resource_group_name   = var.rg-host-pool
  location              = "${var.location}"

  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = azurerm_subnet.avd_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

