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

resource "azurerm_resource_group" "example" {
  name = "rg-example-${random_string.suffix.result}"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name = "vnet-example-${random_string.suffix.result}"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name = "subnet-example-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name = "pip-example-${random_string.suffix.result}"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "example" {
  name = "nic-example-${random_string.suffix.result}"
  location = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name = "ipconfig-example"
    subnet_id = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name = "vm-example-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  size = "Standard_B1s" # B-series VM for cost optimization
  admin_username = "adminuser"
  admin_password = "P@ssw0rd123!"  # Update for security
  network_interface_ids = [azurerm_network_interface.example.id]

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

output "admin_username" {
  value = azurerm_linux_virtual_machine.example.admin_username
}

output "public_ip" {
  value = azurerm_public_ip.example.ip_address
}

output "virtual_machine_id" {
  value = azurerm_linux_virtual_machine.example.id
}
