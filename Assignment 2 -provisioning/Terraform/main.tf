provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "wireapps" {
  name     = "wireapps-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "wireapps" {
  name                = "wireapps-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.wireapps.location
  resource_group_name = azurerm_resource_group.wireapps.name
}

resource "azurerm_subnet" "wireapps" {
  name                 = "wireapps-subnet"
  resource_group_name  = azurerm_resource_group.wireapps.name
  virtual_network_name = azurerm_virtual_network.wireapps.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "wireapps" {
  name                = "wireapps-nic"
  location            = azurerm_resource_group.wireapps.location
  resource_group_name = azurerm_resource_group.wireapps.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.wireapps.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "wireapps" {
  name                = "wireapps-vm"
  resource_group_name = azurerm_resource_group.wireapps.name
  location            = azurerm_resource_group.wireapps.location
  size                = "Standard_B4ms"
  admin_username      = "devuser"
  network_interface_ids = [
    azurerm_network_interface.wireapps.id,
  ]

  admin_ssh_key {
    username   = "devuseruser"
    public_key = file("~/.ssh/id_rsa.pub")  
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.wireapps.public_ip_address
}
