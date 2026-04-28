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

# Resource Group

resource "azurerm_resource_group" "main" {
  name = "rg-${random_string.suffix.result}"
  location = "East US"
}

# Virtual Network

resource "azurerm_virtual_network" "main" {
  name = "vnet-${random_string.suffix.result}"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet

resource "azurerm_subnet" "main" {
  name = "subnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.1.0/24"]
}

# Public IP

resource "azurerm_public_ip" "main" {
  name = "pip-${random_string.suffix.result}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method = "Dynamic"
}

# Network Interface

resource "azurerm_network_interface" "main" {
  name = "nic-${random_string.suffix.result}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "ipconfig-${random_string.suffix.result}"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

# Virtual Machine

resource "azurerm_linux_virtual_machine" "main" {
  name = "vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = "Standard_B1s" # Low-cost B-Series VM
  admin_username = "adminuser"
  admin_ssh_key {
    username = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub") # Change path as needed
  }

  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS" # Cost-effective storage
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
}

# Output important values

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}

output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}
