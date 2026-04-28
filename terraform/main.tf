terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }

  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
}

# Variables for customization
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "example-resource-group"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "vm_size" {
  description = "The size of the VM, optimized for cost"
  type        = string
  default     = "Standard_B1s" # B-series VM - cost-effective for low workloads
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "The admin password for the VM"
  type        = string
  sensitive   = true
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "${var.resource_group_name}-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic" # Dynamic IP for cost-efficiency
}

resource "azurerm_network_interface" "example" {
  name                = "${var.resource_group_name}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Static" # Set static for consistency
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "${var.resource_group_name}-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    create_option        = "FromImage"
    managed_disk_type    = "Standard_LRS" # Use standard managed disks for cost savings
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Outputs for important values
output "public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.example.ip_address
}

output "admin_username" {
  description = "Admin username for VM access"
  value       = azurerm_linux_virtual_machine.example.admin_username
}