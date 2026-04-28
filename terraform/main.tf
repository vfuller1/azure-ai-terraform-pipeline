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

variable "resource_group_name" {
  description = "Name of the resource group"
  type = string
  default = "lowcost-rg"
}

variable "location" {
  description = "Azure location for resources"
  type = string
  default = "East US"
}

resource "random_string" "storage_account_name" {
  length = 16
  lower = true
  number = true
  special = false
}

resource "azurerm_resource_group" "rg" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name = "${var.resource_group_name}-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name = "${var.resource_group_name}-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name = "${var.resource_group_name}-nic"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig1"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = "${var.resource_group_name}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  size = "Standard_B1s" # B-series VM for cost efficiency
  admin_username = "azureuser"
  admin_password = "P@ssword123!" # Change as necessary
  network_interface_ids = [azurerm_network_interface.nic.id]

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

resource "azurerm_storage_account" "storage" {
  name = random_string.storage_account_name.result
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "LRS" # Low redundancy for cost savings
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
