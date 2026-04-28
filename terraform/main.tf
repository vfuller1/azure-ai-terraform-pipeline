terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">=1.0"
}

provider "azurerm" {
  features {}
}

resource "random_string" "storage_account_suffix" {
  length = 10
  special = false
  upper = false
}

resource "random_string" "vm_name" {
  length = 5
  special = false
  upper = false
}

resource "azurerm_resource_group" "rg" {
  name = "rg-${random_string.vm_name.result}"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name = "vnet-${random_string.vm_name.result}"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name = "subnet-${random_string.vm_name.result}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name = "nic-${random_string.vm_name.result}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig-${random_string.vm_name.result}"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name = "vm-${random_string.vm_name.result}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size = "Standard_B1s" # Low-cost B-series VM

  storage_os_disk {
    name = "osdisk-${random_string.vm_name.result}"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS" # Low-cost standard storage
  }

  os_profile {
    computer_name = "hostname-${random_string.vm_name.result}"
    admin_username = "adminuser"
    admin_password = "P@ssword1234!" # Consider parameterizing for security
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

resource "azurerm_storage_account" "storage" {
  name = "storage${random_string.storage_account_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard" # Low-cost standard tier
  account_replication_type = "LRS"     # Low-cost locally redundant storage

  min_tls_version = "TLS1_2"
}

output "vm_id" {
  value = azurerm_virtual_machine.vm.id
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}
