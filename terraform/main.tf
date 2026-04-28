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

  required_version = ">=0.14"
}

provider "azurerm" {
  features {}
}

resource "random_string" "vm_name" {
  length = 8
  special = false
}

resource "random_string" "storage_name" {
  length = 16
  special = false
  lower = true
}

resource "resource_group" "main" {
  name = "rg-${random_string.vm_name.result}"
  location = "East US"
}

resource "azurerm_virtual_network" "main" {
  name = "vnet-${random_string.vm_name.result}"
  address_space = ["10.0.0.0/16"]
  location = resource_group.main.location
  resource_group_name = resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name = "subnet-${random_string.vm_name.result}"
  resource_group_name = resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "main" {
  name = "publicip-${random_string.vm_name.result}"
  location = resource_group.main.location
  resource_group_name = resource_group.main.name
  allocation_method = "Static"
}

resource "azurerm_network_interface" "main" {
  name = "nic-${random_string.vm_name.result}"
  location = resource_group.main.location
  resource_group_name = resource_group.main.name

  ip_configuration {
    name = "ipconfig-${random_string.vm_name.result}"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name = "vm-${random_string.vm_name.result}"
  resource_group_name = resource_group.main.name
  location = resource_group.main.location
  size = "Standard_B1s"  # Low-cost B-series VM
  admin_username = "adminuser"
  admin_password = "P@ssw0rd123!"  # Change to a secure password or use SSH key

  network_interface_ids = [
  azurerm_network_interface.main.id,
  ]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"  # Low-cost standard storage
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }
}

resource "azurerm_storage_account" "main" {
  name = random_string.storage_name.result
  resource_group_name = resource_group.main.name
  location = resource_group.main.location
  account_tier = "Standard"   # Cost-effective storage tier
  account_replication_type = "LRS"       # Locally redundant storage
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}

output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}
