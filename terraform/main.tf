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

resource "azurerm_resource_group" "main" {
  name = "rg-${random_string.suffix.result}"
  location = "East US"
}

resource "azurerm_virtual_network" "main" {
  name = "vnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  address_space = ["10.0.0.0/16"]

  subnet {
    name = "subnet-${random_string.suffix.result}"
    address_prefix = "10.0.1.0/24"
  }
}

resource "azurerm_public_ip" "main" {
  name = "pip-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name = "nic-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location

  ip_configuration {
    name = "ipconfig-${random_string.suffix.result}"
    subnet_id = azurerm_virtual_network.main.subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name = "vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = "Standard_B1s"  # B-series VM for cost-effectiveness
  admin_username = "adminuser"
  admin_password = random_password.password.result
  network_interface_ids = [
  azurerm_network_interface.main.id,
  ]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"  # Optimized storage type for cost
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "20.04-LTS"
    version = "latest"
  }
}

resource "azurerm_storage_account" "main" {
  name = "st${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  account_tier = "Standard"  # Cost-effective tier
  account_replication_type = "LRS"      # Locally redundant storage
}

resource "random_password" "password" {
  length = 12
  special = true
}

variable "vm_admin_password" {
  description = "Admin password for the virtual machine"
  type = string
  sensitive = true
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.main.name
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}
