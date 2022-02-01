terraform {
  backend "azurerm" {
    resource_group_name  = "sadey2k-infra"
    storage_account_name = "sadey2ktstate"
    container_name       = "tstate"
    key                  = "77Q4LUB5o9wRdbPYDt+0kGZP+L8Sj9E/FNXg7lZBQS5z3mLod5cyan4wA19CR1SmlqIRUFQfhuQrPVaGzNhjGw=="
  }

  required_providers {
    azurerm = {
      # Specify what version of the provider we are going to utilise
      source  = "hashicorp/azurerm"
      version = ">= 2.4.1"
    }
  }
}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group - sadey2k-RG
resource "azurerm_resource_group" "rg" {
  name     = "sadey2k-app01"
  location = "UK South"
}
# Create our Virtual Network - sadey2k-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "sadey2kvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "VM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - sadey2ksa
resource "azurerm_storage_account" "sadey2ksa" {
  name                     = "sadey2ksa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "sadey2kenv2"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "sadey2kvm01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - sadey2k-VM01
resource "azurerm_virtual_machine" "sadey2kvm01" {
  name                  = "sadey2kvm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "sadey2kvm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "sadey2kvm01"
    admin_username = "sadey2k"
    admin_password = "Password123$"
  }
  os_profile_windows_config {
  }
}
