terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  description = "The Azure location where resources will be created."
  default = "East US"
}

variable "vm_size" {
  description = "The size of the Virtual Machine."
  default = "Standard_B1s"
}

variable "admin_username" {
  description = "The admin username for the Virtual Machine."
  default = "azureuser"
}

variable "admin_password" {
  description = "The admin password for the Virtual Machine."
  default = "P@ssword1234!" # Change this to a secure password
}

resource "azurerm_resource_group" "example" {
  name = "example-resources"
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name = "example-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "example" {
  name = "example-nic"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name = "example-ip-config"
    subnet_id = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name = "example-vm"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  size = var.vm_size

  admin_username = var.admin_username
  admin_password = var.admin_password
  network_interface_ids = [
  azurerm_network_interface.example.id,
  ]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
}

resource "azurerm_storage_account" "example" {
  name = "examplestoracc"  # This needs to be globally unique
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  account_tier = "Standard"
  account_replication_type = "LRS"  # Locally redundant storage, cost-effective
}

output "vm_id" {
  description = "The ID of the Virtual Machine"
  value = azurerm_linux_virtual_machine.example.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value = azurerm_storage_account.example.name
}

output "resource_group_name" {
  description = "The name of the resource group"
  value = azurerm_resource_group.example.name
}
