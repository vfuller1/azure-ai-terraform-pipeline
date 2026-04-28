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
  description = "The Azure location to deploy resources."
  default = "East US"
}

variable "vm_size" {
  description = "Size of the B-series VM."
  default = "Standard_B1s" # B-series VM optimized for low cost
}

variable "admin_username" {
  description = "Admin username for the VM."
  default = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the VM."
  type = string
  sensitive = true
}

resource "azurerm_resource_group" "main" {
  name = "rg-${random_string.suffix.result}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name = "vnet-${random_string.suffix.result}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name = "subnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefix = "10.0.1.0/24"
}

resource "azurerm_public_ip" "main" {
  name = "pip-${random_string.suffix.result}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name = "nic-${random_string.suffix.result}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "ipconfig-${random_string.suffix.result}"
    subnet_id = azurerm_subnet.main.id
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name = "vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = var.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password
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

output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.main.name
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
