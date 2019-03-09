

# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.21.0"
}

# Create a resource group
resource "azurerm_resource_group" "myvms" {
  name     = "rg_${var.environment}"
  location = "${var.location}"

  tags {
    environment = "${var.environment}"
  }
}

#create a Virtual Network
resource "azurerm_virtual_network" "net_myvms" {
  name                = "net_${var.environment}"
  resource_group_name = "${azurerm_resource_group.myvms.name}"
  location            = "${azurerm_resource_group.myvms.location}"
  address_space       = ["10.0.0.0/8"]
  
  tags {
    environment = "${var.environment}"
  }
}

#Create Master Subnet
resource "azurerm_subnet" "snet_host" {
  name                 = "snet_host"
  resource_group_name  = "${azurerm_resource_group.myvms.name}"
  virtual_network_name = "${azurerm_virtual_network.net_myvms.name}"
  address_prefix       = "10.240.0.0/24"

}

#Create Guest Subnet
resource "azurerm_subnet" "snet_guest" {
  name                 = "snet_guest"
  resource_group_name  = "${azurerm_resource_group.myvms.name}"
  virtual_network_name = "${azurerm_virtual_network.net_myvms.name}"
  address_prefix       = "10.200.0.0/16"

}

#Create Security Group(Firewall Rules) for internal communication
resource "azurerm_network_security_group" "sgrp_int_myvms" {
  name                = "sgrp_int_${var.environment}"
  location            = "${azurerm_resource_group.myvms.location}"
  resource_group_name = "${azurerm_resource_group.myvms.name}"
}

#Create Rules for Security Group - ssh port and external access
resource "azurerm_network_security_rule" "rule_int_myvms" {
  name                        = "rule_int_${var.environment}"
  priority                    = 100
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges      = ["22","6443"]
  source_address_prefixes     = ["10.240.0.0/24","10.200.0.0/16"]
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.myvms.name}"
  network_security_group_name = "${azurerm_network_security_group.sgrp_int_myvms.name}"

}

#Create Security Group(Firewall Rules) for external communication
resource "azurerm_network_security_group" "sgrp_ext_myvms" {
  name                = "sgrp_ext_${var.environment}"
  location            = "${azurerm_resource_group.myvms.location}"
  resource_group_name = "${azurerm_resource_group.myvms.name}"

  tags {
    environment = "${var.environment}"
  }
}

#Create Rules for External Security Group - Allow SSH and HTTPS
resource "azurerm_network_security_rule" "rule_ext_myvms" {
  name                        = "rule_ext_${var.environment}"
  priority                    = 101
  access                      = "Allow"
  direction                   = "Inbound"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_ranges     = ["22","6443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.myvms.name}"
  network_security_group_name = "${azurerm_network_security_group.sgrp_ext_myvms.name}"

}

#Create Public Ip for LoadBalancer
resource "azurerm_public_ip" "ip_ext_LB_myvms" {
  name                = "ip_ext_LB_${var.environment}"
  location            = "${azurerm_resource_group.myvms.location}"
  resource_group_name = "${azurerm_resource_group.myvms.name}"
  allocation_method   = "Static"

  tags {
    environment = "${var.environment}"
  }
}

#Create LoadBalancer for myvmsing
resource "azurerm_lb" "lb_myvms" {
  name                = "lb_${var.environment}"
  location            = "${azurerm_resource_group.myvms.location}"
  resource_group_name = "${azurerm_resource_group.myvms.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.ip_ext_LB_myvms.id}"
  }

  tags {
    environment = "${var.environment}"
  }
}

#Create Backend pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "pool_myvms" {
  resource_group_name = "${azurerm_resource_group.myvms.name}"
  loadbalancer_id     = "${azurerm_lb.lb_myvms.id}"
  name                = "pool_${var.environment}"

}

################################################
# Begin VM Creation
################################################

#Create Public Ip for servers
resource "azurerm_public_ip" "ip_ext_myvms" {
  count               = "3"
  name                = "ipExt${var.environment}${count.index}"
  location            = "${azurerm_resource_group.myvms.location}"
  resource_group_name = "${azurerm_resource_group.myvms.name}"
  allocation_method   = "Dynamic"

  tags {
    environment = "${var.environment}"
  }
}


#Create  NIC for systems
resource "azurerm_network_interface" "nic_myvms" {
  count               = "${var.servercount}"
  name                = "ni-${var.environment}-${count.index}"
  location            = "${azurerm_resource_group.myvms.location}"
  resource_group_name = "${azurerm_resource_group.myvms.name}"

  ip_configuration {
    name                          = "ip_int_${var.environment}"
    subnet_id                     = "${azurerm_subnet.snet_host.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${lookup(var.ip_private_myvms, count.index)}"
    public_ip_address_id          = "${azurerm_public_ip.ip_ext_myvms.*.id[count.index]}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.pool_myvms.id}"]
    primary = true
  }

  tags {
    environment = "${var.environment}"
  }
}

#Create AS for controllers
resource "azurerm_availability_set" "as_myvms" {
  name                = "as_${var.environment}"
  location            = "${azurerm_resource_group.myvms.location}"
  resource_group_name = "${azurerm_resource_group.myvms.name}"
  managed             = true

  tags {
    environment = "${var.environment}"
  }
}


#Create Storage Accounts for boot diagnostics for workers
resource "azurerm_storage_account" "stracct_myvms" {
    count               = "${var.servercount}"
    name                = "diag${var.environment}${count.index}"
    location            = "${azurerm_resource_group.myvms.location}"
    resource_group_name = "${azurerm_resource_group.myvms.name}"
    account_replication_type = "${var.storage_replication_type}"
    account_tier = "${var.storage_account_tier}"

    tags {
    environment = "${var.environment}"
  }
}

#Create desktop VMs
resource "azurerm_virtual_machine" "vm_myvms" {
    count               = "${var.servercount}"
    name                  = "vm${var.environment}${count.index}"
    location            = "${azurerm_resource_group.myvms.location}"
    resource_group_name = "${azurerm_resource_group.myvms.name}"
    network_interface_ids = ["${element(azurerm_network_interface.nic_myvms.*.id, count.index)}"]
    availability_set_id = "${azurerm_availability_set.as_myvms.id}"

    vm_size               = "${var.vm_size}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true


  #Image reference
  storage_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }

  #Create Storage Disks
  storage_os_disk {
      name              = "osdisk-${var.environment}-${count.index}"
      caching           = "ReadWrite"
      create_option     = "${var.createoption}"
      managed_disk_type = "Standard_LRS"
    }
  
  os_profile {
    computer_name  = "vm-${var.environment}-${count.index}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${var.environment}"
  }
}

#capture variable outputs for use with other plans 
output "vmnames" {
  value = ["${azurerm_virtual_machine.vm_myvms.*.name}"]
}


output "extips" {
  value = ["${azurerm_public_ip.ip_ext_myvms.*.ip_address}"]
}


