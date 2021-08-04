resource "azurerm_resource_group" "az_k8s_rg" {
  name     = "az-k8s-rg"
  location = "centralindia"
}

resource "azurerm_virtual_network" "az_k8s_vnet" {

  depends_on = [
    azurerm_resource_group.az_k8s_rg
  ]

  name                = "az-k8s-network"
  address_space       = ["10.2.0.0/16"]
  location            = "centralindia"
  resource_group_name = azurerm_resource_group.az_k8s_rg.name
}

resource "azurerm_subnet" "az_k8s_subnet" {

  depends_on = [
    azurerm_resource_group.az_k8s_rg,
    azurerm_virtual_network.az_k8s_vnet
  ]

  name                 = "az-k8s-subnet"
  resource_group_name  = azurerm_resource_group.az_k8s_rg.name
  virtual_network_name = azurerm_virtual_network.az_k8s_vnet.name
  address_prefixes       = ["10.2.0.0/24"]
}

resource "azurerm_public_ip" "az_k8s_publicip" {

  depends_on = [
    azurerm_resource_group.az_k8s_rg
  ]

  name                         = "az-k8s-publicip"
  location                     = "centralindia"
  resource_group_name          = azurerm_resource_group.az_k8s_rg.name
  allocation_method            = "Dynamic"
}

resource "azurerm_network_security_group" "az_k8s_nsg" {

  depends_on = [
    azurerm_resource_group.az_k8s_rg
  ]

  name                = "az-allowall-nsg"
  location            = "centralindia"
  resource_group_name = azurerm_resource_group.az_k8s_rg.name

  security_rule {
    name                       = "allowall"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "az_k8s_ni" {

  depends_on = [
    azurerm_resource_group.az_k8s_rg,
    azurerm_subnet.az_k8s_subnet,
    azurerm_public_ip.az_k8s_publicip
  ]

  name                        = "az-k8s-ni"
  location                    = "centralindia"
  resource_group_name         = azurerm_resource_group.az_k8s_rg.name
    
  ip_configuration {
    name                          = "K8s-Slave-NicConfiguration"
    subnet_id                     = azurerm_subnet.az_k8s_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.az_k8s_publicip.id
  }
}

resource "azurerm_network_interface_security_group_association" "az_k8s_sg_ni_association" {

  depends_on = [
    azurerm_network_interface.az_k8s_ni,
    azurerm_network_security_group.az_k8s_nsg
  ]

  network_interface_id      = azurerm_network_interface.az_k8s_ni.id
  network_security_group_id = azurerm_network_security_group.az_k8s_nsg.id
}

resource "azurerm_linux_virtual_machine" "az_k8s_slave" {

  depends_on = [
    azurerm_resource_group.az_k8s_rg,
    azurerm_network_interface_security_group_association.az_k8s_sg_ni_association
  ]

  name                  = "az-k8s-slave"
  location              = "centralindia"
  resource_group_name   = azurerm_resource_group.az_k8s_rg.name
  network_interface_ids = [azurerm_network_interface.az_k8s_ni.id]
  size                  = "Standard_B2s"
  
  os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "openlogic"
    offer     = "centos"
    sku       = "8.0"
    version   = "latest"
  }

  computer_name  = "az-k8s-slave"
  admin_username = "centos"
  
  admin_ssh_key {
    username       = "centos"
    public_key     =  file("../k8s-multi-cloud-key-public.pub")
  }
}