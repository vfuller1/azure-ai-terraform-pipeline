terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }

  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
}

# Variable definitions for customization

variable "location" {
  description = "The Azure region to deploy resources"
  default = "East US"
}

variable "vm_size" {
  description = "The size of the virtual machine"
  default = "Standard_B1s" # B-series VM size optimized for low cost
}

variable "admin_username" {
  description = "Admin username for the VM"
  default = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type = string
  sensitive = true
}

# Resource group to contain resources

resource "azurerm_resource_group" "main" {
  name = "low-cost-rg"
  location = var.location
}

# Virtual network for basic networking

resource "azurerm_virtual_network" "main" {
  name = "low-cost-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet definition

resource "azurerm_subnet" "main" {
  name = "low-cost-subnet"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.1.0/24"]
}

# Network interface for the VM

resource "azurerm_network_interface" "main" {
  name = "low-cost-nic"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine definition

resource "azurerm_linux_virtual_machine" "main" {
  name = "low-cost-vm"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = var.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS" # Standard storage for cost savings
  }

  os_profile {
    computer_name = "low-cost-vm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
}

# Output essential information

output "vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}

output "public_ip" {
  value = azurerm_network_interface.main.private_ip_address
}
