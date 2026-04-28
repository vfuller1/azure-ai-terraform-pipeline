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

variable "location" {
  description = "The Azure location where resources will be created."
  default = "East US"
}

variable "vm_size" {
  description = "The size of the Virtual Machine."
  default = "Standard_B1s"  # B-series VM for cost optimization
}

resource "random_string" "storage_account_name" {
  length = 16
  special = false
  upper = false
  lower = true
  number = true
}

resource "azurerm_resource_group" "rg" {
  name = "rg-${random_string.storage_account_name.result}"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name = "vnet-${random_string.storage_account_name.result}"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name = "subnet-${random_string.storage_account_name.result}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name = "nic-${random_string.storage_account_name.result}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig-${random_string.storage_account_name.result}"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = "vm-${random_string.storage_account_name.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  size = var.vm_size
  admin_username = "adminuser"
  admin_password = "P@ssw0rd1234!" # Update with a secure password or use SSH keys

  network_interface_ids = [
  azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "20.04-LTS"
    version = "latest"
  }
}

resource "azurerm_storage_account" "storage" {
  name = lower(random_string.storage_account_name.result)
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"  # Low-cost storage tier
  account_replication_type = "LRS"      # Locally redundant storage for cost efficiency
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
