terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

resource "random_string" "storage_account_suffix" {
  length = 10
  upper = false
  special = false
}

resource "random_string" "vm_name_suffix" {
  length = 5
  upper = false
  special = false
}

resource "azurerm_resource_group" "main" {
  name = "rg-${random_string.vm_name_suffix.result}"
  location = "East US"
}

resource "azurerm_virtual_network" "main" {
  name = "vnet-${random_string.vm_name_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  address_space = ["10.0.0.0/16"]

  subnet {
    name = "subnet-${random_string.vm_name_suffix.result}"
    address_prefix = "10.0.1.0/24"
  }
}

resource "azurerm_network_interface" "main" {
  name = "nic-${random_string.vm_name_suffix.result}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "ipconfig-${random_string.vm_name_suffix.result}"
    subnet_id = azurerm_virtual_network.main.subnet[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_storage_account" "main" {
  name = "st${random_string.storage_account_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled = false
}

resource "azurerm_linux_virtual_machine" "main" {
  name = "vm-${random_string.vm_name_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = "Standard_B1s"  # Low cost B-series VM
  admin_username = "azureuser"
  admin_password = "Password12345!" # Use secure methods for password in production

  network_interface_ids = [
  azurerm_network_interface.main.id,
  ]

  os_disk {
    caching = "ReadWrite"
    managed_disk_type = "Standard_LRS"  # Standard storage for cost efficiency
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}
