terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "azurerm_resource_group" "example" {
  name     = "rg-${random_string.suffix.result}"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                = "subnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes    = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "nic-${random_string.suffix.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "ipconfig-${random_string.suffix.result}"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_storage_account" "example" {
  name                  = "st${random_string.suffix.result}"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  account_tier         = "Standard"
  account_replication_type = "LRS"
  min_tls_version      = "TLS1_2"
}

resource "random_password" "password" {
  length  = 16
  special = true
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s" # Low-cost B-series VM
  admin_username      = "adminuser"
  admin_password      = random_password.password.result

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    create_option        = "FromImage"
    managed_disk_type    = "Standard_LRS" # Cost-effective storage
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.example.name
}

output "virtual_machine_name" {
  value = azurerm_linux_virtual_machine.example.name
}

output "storage_account_name" {
  value = azurerm_storage_account.example.name
}