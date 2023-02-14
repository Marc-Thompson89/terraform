# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "host-pool-name" {
  resource_group_name      = var.rg-host-pool
  location                 = var.location
  name                     = var.host-pool-name
  friendly_name            = var.host-pool-name
  validate_environment     = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;enablerdsaadauth:i:1"
  description              = "${var.prefix} Terraform Host Pool"
  type                     = "Pooled"
  maximum_sessions_allowed = 5
  load_balancer_type       = "BreadthFirst"
depends_on          = [azurerm_resource_group.rg-host-pool]
}

resource "time_rotating" "avd_registration_experation" {
  rotation_days = 29
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.host-pool-name.id
  expiration_date = time_rotating.avd_registration_experation.rotation_rfc3339
}


# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace_name
  resource_group_name = var.rg-host-pool
  location            = var.location
  friendly_name       = "${var.prefix} Workspace"
  description         = "${var.prefix} Workspace"
}

# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "avd" {
  resource_group_name = var.rg-host-pool
  host_pool_id        = azurerm_virtual_desktop_host_pool.host-pool-name.id
  location            = var.location
  type                = "Desktop"
  name                = "${var.prefix}-ag"
  friendly_name       = "Desktop AppGroup"
  description         = "AVD application group"
  depends_on          = [azurerm_virtual_desktop_host_pool.host-pool-name, azurerm_virtual_desktop_workspace.workspace]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  application_group_id = azurerm_virtual_desktop_application_group.avd.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}

#RBAC
data "azuread_user" "aad_users" {
  for_each            = toset(var.avd_users)
  user_principal_name = format("%s", each.key)
}
data "azurerm_role_definition" "app-def-role" {
  name = "Desktop Virtualization User"
}

data "azurerm_role_definition" "rg-def-role" {
  name = "Virtual Machine User Login"
}

resource "azuread_group" "aad_group" {
  display_name     = var.aad_group_name
  security_enabled = true
}

resource "azuread_group_member" "aad_group_member" {
  for_each         = data.azuread_user.aad_users
  group_object_id  = azuread_group.aad_group.id
  member_object_id = each.value["id"]
}

resource "azurerm_role_assignment" "app-role" {
  scope              = azurerm_virtual_desktop_application_group.avd.id
  role_definition_id = data.azurerm_role_definition.app-def-role.id
  principal_id       = azuread_group.aad_group.id
  depends_on= [azurerm_virtual_desktop_application_group.avd]
}

resource "azurerm_role_assignment" "rg-role" {
  scope              = azurerm_resource_group.rg-host-pool.id
  role_definition_id = data.azurerm_role_definition.rg-def-role.id
  principal_id       = azuread_group.aad_group.id
  depends_on= [data.azurerm_role_definition.rg-def-role]
}