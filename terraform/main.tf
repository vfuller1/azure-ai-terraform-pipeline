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
}

provider "azurerm" {
  features {}
}

provider "random" {}

# Variables for customization

variable "location" {
  description = "The Azure location where resources will be created."
  default = "East US"
}

variable "vm_size" {
  description = "Size of the Virtual Machine."
  default = "Standard_B1s" # B-series VMs for low cost
}

# Random string for unique resource names

resource "random_string" "vm_name" {
  length = 8
  special = false
  upper = false
}

resource "random_string" "storage_account_name" {
  length = 16
  special = false
  upper = false
}

resource "random_string" "vnet_name" {
  length = 10
  special = false
  upper = false
}

resource "random_string" "subnet_name" {
  length = 10
  special = false
  upper = false
}

# Resource Group

resource "azurerm_resource_group" "main" {
  name = "${random_string.vnet_name.result}-rg"
  location = var.location
}

# Virtual Network

resource "azurerm_virtual_network" "main" {
  name = "${random_string.vnet_name.result}-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet

resource "azurerm_subnet" "main" {
  name = "${random_string.subnet_name.result}-subnet"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.1.0/24"]
}

# Network Interface

resource "azurerm_network_interface" "main" {
  name = "${random_string.vm_name.result}-nic"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine

resource "azurerm_linux_virtual_machine" "main" {
  name = "${random_string.vm_name.result}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = var.vm_size
  admin_username = "adminuser"
  admin_password = "P@ssword123!" # Use secure method for password
  network_interface_ids = [azurerm_network_interface.main.id]
  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
  }
  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
}

# Storage Account for standard storage

resource "azurerm_storage_account" "main" {
  name = "${random_string.storage_account_name.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  account_tier = "Standard"
  account_replication_type = "LRS" # Locally redundant storage for cost efficiency
  enable_https_traffic_only = true
}

# Outputs for important values

output "vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}

output "storage_account_id" {
  value = azurerm_storage_account.main.id
}
