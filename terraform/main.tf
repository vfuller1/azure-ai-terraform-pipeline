terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "random" {}

# Variables for customization

variable "location" {
  description = "The location for all resources"
  default = "East US"
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  default = "Standard_B1s"  # B-series VM optimized for low cost
}

# Resources

resource "random_string" "storage_account_name" {
  length = 16
  special = false
  upper = false
  lower = true
  number = true
}

resource "azurerm_resource_group" "example" {
  name = "rg-${random_string.storage_account_name.result}"
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name = random_string.storage_account_name.result
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  account_tier = "Standard"
  account_replication_type = "LRS" # Locally Redundant Storage for cost efficiency

  enforce_https = true
}

resource "azurerm_virtual_network" "example" {
  name = "vnet-${random_string.storage_account_name.result}"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name = "subnet-${random_string.storage_account_name.result}"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "example" {
  name = "nic-${random_string.storage_account_name.result}"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name = "ipconfig-${random_string.storage_account_name.result}"
    subnet_id = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name = "vm-${random_string.storage_account_name.result}"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  size = var.vm_size
  admin_username = "adminuser"
  admin_password = "P@ssword1234!" # Consider using secure options for production

  network_interface_ids = [
  azurerm_network_interface.example.id,
  ]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
}

# Outputs

output "storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "vm_public_ip" {
  value = azurerm_network_interface.example.private_ip_address
}

output "resource_group_name" {
  value = azurerm_resource_group.example.name
}
