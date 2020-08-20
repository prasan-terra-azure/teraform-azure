# Create Resource Group
resource "azurerm_resource_group" "rg" {
    name = "Terra-K8s-Practise"
    location = var.location   
    tags = var.tags
}

# Create Vitural Network
resource "azurerm_virtual_network" "vnet" {
    name = "${var.prefix}Vnet"
    address_space = ["10.0.0.0/16"]
    location = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags
}

# Create Subnet 
resource "azurerm_subnet" "subnet" {
    name = "${var.prefix}Subnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.0.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "${var.prefix}PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_virtual_machine.vm.resource_group_name
  depends_on = [azurerm_virtual_machine.vm]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  security_rule {
    name                       = "SSH-VPN"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "14.140.98.138/32"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "K8s-VPN-ports"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "14.140.98.138/32"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH-direct"
    priority                   = 1015
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "49.207.208.185/32"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "K8s-direct-ports"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "49.207.208.185/32"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                      = "${var.prefix}NIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  tags                      = var.tags

  ip_configuration {
    name                          = "${var.prefix}NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.prefix}-Master"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_D2S_v3"
  delete_os_disk_on_termination = true
  tags                  = var.tags

  storage_os_disk {
    name              = "${var.prefix}OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = lookup(var.sku, var.location)
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.prefix}-Master"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "null_resource" "bootstrap" {
  connection {
      host     = data.azurerm_public_ip.ip.ip_address
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
    }
  
  provisioner "file" {
    source = "scripts/install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "file" {
    source = "scripts/kube-init.sh"
    destination = "/tmp/kube-init.sh"
  }

  provisioner "remote-exec" {
     inline = [ 
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done; sudo rm /var/lib/apt/lists/* ;" ,
      "sudo chown root:root /tmp/install.sh && sudo chown root:root /tmp/kube-init.sh",
      "sudo chmod +x /tmp/install.sh && sudo chmod +x /tmp/kube-init.sh",
      "sudo /tmp/install.sh", 
      "sudo /tmp/kube-init.sh", 
      ]
  }
}