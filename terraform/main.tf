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

  required_version = ">=1.0.0"
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length = 8
  special = false
}

# Resource Group

resource "azurerm_resource_group" "example" {
  name = "rg-example-${random_string.suffix.result}"
  location = "East US" # Choosing East US for cost efficiency
}

# Virtual Network

resource "azurerm_virtual_network" "example" {
  name = "vnet-example-${random_string.suffix.result}"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Subnet

resource "azurerm_subnet" "example" {
  name = "subnet-example-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes = ["10.0.1.0/24"]
}

# Public IP

resource "azurerm_public_ip" "example" {
  name = "public-ip-example-${random_string.suffix.result}"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method = "Dynamic" # Using dynamic allocation to save costs
}

# Network Interface

resource "azurerm_network_interface" "example" {
  name = "nic-example-${random_string.suffix.result}"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name = "ipconfig-example-${random_string.suffix.result}"
    subnet_id = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

# B-Series Virtual Machine

resource "azurerm_linux_virtual_machine" "example" {
  name = "vm-example-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  size = "Standard_B1s" # Low-cost B-series VM
  admin_username = "adminuser"
  admin_password = "P@ssword1234!" # Use secure password management in production

  network_interface_ids = [
  azurerm_network_interface.example.id,
  ]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS" # Low-cost Standard LRS disk
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "20.04-LTS"
    version = "latest"
  }
}

# Storage Account

resource "azurerm_storage_account" "example" {
  name = "st${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  account_tier = "Standard"      # Cost-effective standard tier
  account_replication_type = "LRS"          # Low-cost locally redundant storage
}

# Outputs

output "resource_group_name" {
  value = azurerm_resource_group.example.name
}

output "virtual_machine_id" {
  value = azurerm_linux_virtual_machine.example.id
}

output "storage_account_name" {
  value = azurerm_storage_account.example.name
}
