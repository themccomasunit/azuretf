
variable "environment" {
  type= "string"
  default = "myvms"
}


variable "location" {
    type = "string"
    default = "Central Us"
}


variable "servercount" {
  description = "number of servers to create"
  default = "5"
}

variable "createoption" {
  description = "Create new or attch to already existing disk"

  default = "FromImage"
}

variable "ip_private_myvms" {
  description = ""

  default = {
    "0" = "10.240.0.4"
    "1" = "10.240.0.5"
    "2" = "10.240.0.6"
    "3" = "10.240.0.7"
    "4" = "10.240.0.8"
  }
}

variable "storage_account_tier" {
  description = "Defines the Tier of storage account to be created. Valid options are Standard and Premium."
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Defines the Replication Type to use for this storage account. Valid options include LRS, GRS etc."
  default     = "LRS"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_DS2_v2"
}

variable "admin_username" {
  description = "administrator user name"
  default     = "azureadmin"
}

variable "admin_password" {
  description = "administrator password"
  default     = "azur3admin!"
}