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
  default     = "low-cost-rg"
}

variable "location" {
  description = "The Azure region for resources"
  type        = string
  default     = "East US"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"  # Optimized for low cost
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  sensitive   = true
}
# Resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}
# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}
# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.resource_group_name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_configuration {
    name                          = "${var.resource_group_name}-ipconfig"
    subnet_id                    = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.resource_group_name}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
  azurerm_network_interface.main.id,
  ]
  os_disk {
    caching              = "ReadWrite"
    create_option        = "FromImage"
    managed_disk_type    = "Standard_LRS"  # Standard storage for cost efficiency
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
}
# Outputs for important values
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vm_public_ip" {
  value = azurerm_network_interface.main.private_ip_address
}

output "vm_admin_username" {
  value = azurerm_linux_virtual_machine.main.admin_username
  sensitive = true
}
