
variable "environment" {
  type= "string"
  default = "tgo2"
}


variable "location" {
    type = "string"
    default = "East Us"
}


variable "servercount" {
  description = "number of servers to create"
  default = "3"
}

variable "createoption" {
  description = "Create new or attch to already existing disk"

  default = "FromImage"
}

variable "ip_private_train" {
  description = ""

  default = {
    "0" = "10.240.0.4"
    "1" = "10.240.0.5"
    "2" = "10.240.0.6"
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