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

resource "azurerm_virtual_network" "vnet" {
  name = "vnet-${random_string.suffix.result}"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name = "subnet-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name = "pip-${random_string.suffix.result}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Dynamic"  # Cost-effective dynamic IP
}

resource "azurerm_network_interface" "nic" {
  name = "nic-${random_string.suffix.result}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig-${random_string.suffix.result}"
    subnet_id = azurerm_subnet.subnet.id
    public_ip_address_id = azurerm_public_ip.public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = "vm-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  size = "Standard_B1s"  # B-series VM for cost efficiency
  admin_username = "adminuser"
  admin_password = "P@ssword123!"  # Secure password configuration
  network_interface_ids = [
  azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"  # Cost-effective storage
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "20.04-LTS"
    version = "latest"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}
