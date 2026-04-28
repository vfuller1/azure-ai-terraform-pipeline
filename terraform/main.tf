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

  required_version = ">=0.12"
}

provider "azurerm" {
  features {}
}

provider "random" {}

# Variable definitions for customization

variable "resource_group_name" {
  description = "Name of the resource group"
  type = string
  default = "tf-rg"
}

variable "location" {
  description = "Azure location"
  type = string
  default = "East US"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type = string
  default = "Standard_B1s" # B-series VM for cost optimization
}

# Generate random string for unique storage account name

resource "random_string" "storage_account_suffix" {
  length = 8
  special = false
  upper = false
}

# Resource Group

resource "azurerm_resource_group" "main" {
  name = var.resource_group_name
  location = var.location
}

# Virtual Network

resource "azurerm_virtual_network" "main" {
  name = "${var.resource_group_name}-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet

resource "azurerm_subnet" "main" {
  name = "${var.resource_group_name}-subnet"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.1.0/24"]
}

# Public IP

resource "azurerm_public_ip" "main" {
  name = "${var.resource_group_name}-pip"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method = "Dynamic"
}

# Network Interface

resource "azurerm_network_interface" "main" {
  name = "${var.resource_group_name}-nic"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "${var.resource_group_name}-ipconfig"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

# Virtual Machine

resource "azurerm_linux_virtual_machine" "main" {
  name = "${var.resource_group_name}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = var.vm_size
  admin_username = "adminuser"
  admin_password = "P@ssw0rd1234!"  # Change this in actual use
  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    disk_size_gb = 30  # Standard disk size for cost
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "20.04-LTS"
    version = "latest"
  }
}

# Storage Account

resource "azurerm_storage_account" "main" {
  name = "st${random_string.storage_account_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  account_tier = "Standard"
  account_replication_type = "LRS"  # Locally-redundant storage for cost optimization
}

# Outputs for important values

output "vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}

output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}
