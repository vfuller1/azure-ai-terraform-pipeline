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

  required_version = ">=1.0"
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length = 8
  special = false
  number = true
  upper = false
}

variable "location" {
  description = "The Azure region where resources will be created."
  default = "East US"
}

variable "vm_size" {
  description = "Size of the virtual machine."
  default = "Standard_B1s"  # Low-cost B-series VM
}

resource "azurerm_resource_group" "main" {
  name = "rg-${random_string.suffix.result}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name = "vnet-${random_string.suffix.result}"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name = "subnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "main" {
  name = "nic-${random_string.suffix.result}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "ipconfig-${random_string.suffix.result}"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "main" {
  name = "vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = var.vm_size
  admin_username = "adminuser"
  admin_password = "P@ssword1234!"  # Change as necessary
  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    caching = "ReadWrite"
    name = "osdisk-${random_string.suffix.result}"
    disk_size_gb = 30  # Standard for low-cost
    managed_disk_type = "Standard_LRS"  # Low-cost storage option
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2019-Datacenter"
    version = "latest"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "virtual_network_name" {
  value = azurerm_virtual_network.main.name
}

output "subnet_name" {
  value = azurerm_subnet.main.name
}

output "network_interface_name" {
  value = azurerm_network_interface.main.name
}

output "virtual_machine_name" {
  value = azurerm_windows_virtual_machine.main.name
}
