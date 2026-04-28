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

variable "resource_group_name" {
  description = "Name of the resource group"
  type = string
  default = "low-cost-rg"
}

variable "location" {
  description = "Azure region for resources"
  type = string
  default = "East US"
}

variable "vm_size" {
  description = "Size of the VM"
  type = string
  default = "Standard_B1s"
}

# Resource Group

resource "azurerm_resource_group" "main" {
  name = var.resource_group_name
  location = var.location
}

# Random string for unique storage account name

resource "random_string" "storage_account_suffix" {
  length = 8
  special = false
  upper = false
}

# Storage Account

resource "azurerm_storage_account" "main" {
  name = "st${random_string.storage_account_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  account_tier = "Standard"  # Cost optimization: using standard tier
  account_replication_type = "LRS"       # Locally redundant storage
}

# Virtual Network

resource "azurerm_virtual_network" "main" {
  name = "vnet-${random_string.storage_account_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  address_space = ["10.0.0.0/16"]
}

# Subnet

resource "azurerm_subnet" "main" {
  name = "subnet-${random_string.storage_account_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.1.0/24"]
}

# Network Interface

resource "azurerm_network_interface" "main" {
  name = "nic-${random_string.storage_account_suffix.result}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "ipconfig-${random_string.storage_account_suffix.result}"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine

resource "azurerm_linux_virtual_machine" "main" {
  name = "vm-${random_string.storage_account_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = var.vm_size
  admin_username = "adminuser"
  admin_password = "P@ssw0rd123!"  # You may want to customize this for security
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

# Outputs for important values

output "vm_id" {
  description = "The ID of the virtual machine"
  value = azurerm_linux_virtual_machine.main.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value = azurerm_storage_account.main.name
}
