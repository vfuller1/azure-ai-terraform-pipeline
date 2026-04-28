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
}

variable "location" {
  description = "The Azure region to deploy resources."
  default = "East US"
}

variable "vm_size" {
  description = "The size of the Virtual Machine."
  default = "Standard_B1s" # B-series VM for low cost
}

resource "azurerm_resource_group" "example" {
  name = "rg-${random_string.suffix.result}"
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name = "vnet-${random_string.suffix.result}"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name = "subnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "example" {
  name = "nic-${random_string.suffix.result}"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name = "ipconfig-${random_string.suffix.result}"
    subnet_id = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name = "vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  size = var.vm_size
  admin_username = "azureuser"
  admin_password = "P@ssword123!" # Replace with a more secure password or use SSH keys
  network_interface_ids = [azurerm_network_interface.example.id]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS" # Standard SSD for cost optimization
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "20.04-LTS"
    version = "latest"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.example.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.example.name
}

output "admin_username" {
  value = azurerm_linux_virtual_machine.example.admin_username
}
