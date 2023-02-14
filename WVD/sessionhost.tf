#AVD Session Hosts
resource "azurerm_windows_virtual_machine" "avd-sessionhosts" {
  count                 = var.rdsh_count
  name                  = "${var.prefix}-avd-${count.index + 1}"
  resource_group_name   = var.rg-host-pool
  location              = "${var.location}"
  size                  = "Standard_D4s_v4"
  license_type          = "Windows_Client"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  enable_automatic_updates = true
  provision_vm_agent    = true
  

  os_disk {
    name                 = "${lower(var.prefix)}-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-avd"
    version   = "latest"
  }

  identity {
    type  = "SystemAssigned"
  }

  depends_on = [azurerm_network_interface.avd_vm_nic]
}

#Domain join - AAD

locals {
  shutdown_command     = "shutdown -r -t 10"
  exit_code_hack       = "exit 0"
  commandtorun         = "New-Item -Path HKLM:/SOFTWARE/Microsoft/RDInfraAgent/AADJPrivate"
  powershell_command   = "${local.commandtorun}; ${local.shutdown_command}; ${local.exit_code_hack}"
}


resource "azurerm_virtual_machine_extension" "AVDModule" {
  depends_on = [
      azurerm_windows_virtual_machine.avd-sessionhosts
  ]
  count                = var.rdsh_count
  name                 = "${var.prefix}${count.index + 1}-avdmodule"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd-sessionhosts.*.id[count.index]
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
        "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
        "ConfigurationFunction": "Configuration.ps1\\AddSessionHost",
        "Properties" : {
          "hostPoolName" : "${azurerm_virtual_desktop_host_pool.host-pool-name.name}",
          "aadJoin": true
        }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.avd.token}"
    }
  }

PROTECTED_SETTINGS

}
resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  depends_on = [
      azurerm_windows_virtual_machine.avd-sessionhosts,
        azurerm_virtual_machine_extension.AVDModule
  ]
  count                = var.rdsh_count
  name                 = "AADLoginForWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd-sessionhosts.*.id[count.index]
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true
}
resource "azurerm_virtual_machine_extension" "addaadjprivate" {
    depends_on = [
      azurerm_virtual_machine_extension.AADLoginForWindows
    ]
  count                = var.rdsh_count
  name                 = "AADJPRIVATE"
  virtual_machine_id   =    azurerm_windows_virtual_machine.avd-sessionhosts.*.id[count.index]
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}
