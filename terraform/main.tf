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

resource "azurerm_resource_group" "rg" {
  name = "rg-${random_string.suffix.result}"
  location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name = "st${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_network" "vnet" {
  name = "vnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name = "subnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name = "pip-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  allocation_method = "Static"
}

resource "azurerm_network_interface" "nic" {
  name = "nic-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  ip_configuration {
    name = "ipconfig-${random_string.suffix.result}"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name = "vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  size = "Standard_B1s"  # Low-cost B-series VM
  admin_username = "adminuser"
  admin_password = "P@ssword1234!"  # Change for security
  network_interface_ids = [azurerm_network_interface.nic.id]
  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"  # Low-cost standard storage
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2019-Datacenter"
    version = "latest"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.vm.name
}
