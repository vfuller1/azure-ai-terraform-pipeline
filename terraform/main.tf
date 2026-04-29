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

  backend "azurerm" {
    resource_group_name = "tfstate-rg"
    storage_account_name = "terraformapproval"
    container_name = "tfstate"
    key = "terraform.tfstate"
  }
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

resource "azurerm_storage_account" "main" {
  name = "st${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_network" "main" {
  name = "vnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name = "subnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "main" {
  name = "nic-${random_string.suffix.result}"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name = "ipconfig-${random_string.suffix.result}"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name = "vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location
  size = "Standard_B1s"  # Cost-effective B-series VM
  admin_username = "adminuser"
  admin_password = "P@ssword123!"  # Use secure password management
  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    caching = "ReadWrite"
    managed_disk_type = "Standard_LRS"  # Optimizing storage cost
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "20.04-lts"
    version = "latest"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "virtual_machine_id" {
  value = azurerm_linux_virtual_machine.main.id
}
