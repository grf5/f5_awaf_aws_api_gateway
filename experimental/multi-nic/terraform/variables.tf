resource "random_id" "buildSuffix" {
  byte_length = 2
}
variable "projectPrefix" {
  description = "projectPrefix name for tagging"
  default     = "gwlb-bigip"
}
variable "resourceOwner" {
  description = "Owner of the deployment for tagging purposes"
  default     = "bigip-team"
}
variable "awsRegion" {
  description = "aws region"
  type        = string
  default     = "us-east-2"
}
variable "awsAz1" {
  description = "Availability zone, will dynamically choose one if left empty"
  type        = string
  default     = null
}
variable "awsAz2" {
  description = "Availability zone, will dynamically choose one if left empty"
  type        = string
  default     = null
}
variable "bigipAdminPassword" {
  description = "BIG-IP Admin Password (set on first boot)"
  default = "f5c0nfig123!"
  type = string
  sensitive = true
}
variable "bigipLicenseAZ1" {
  description = "BIG-IP License for AZ1 instance"
  type = string
}
variable "bigipLicenseAZ2" {
  description = "BIG-IP License for AZ2 instance"
  type = string
}
variable "juiceShopAPICIDR" {
  description = "CIDR block for entire Juice Shop API VPC"
  default = "10.20.0.0/16"
  type = string
}
variable "juiceShopAPISubnetAZ1" {
  description = "Subnet for Juice Shop API AZ1"
  default = "10.20.100.0/24"
  type = string
}
variable "juiceShopAPISubnetAZ2" {
  description = "Subnet for Juice Shop API AZ2"
  default = "10.20.200.0/24"
  type = string
}
variable "f5BigIPCIDR" {
  description = "CIDR block for entire Security Services VPC"
  default = "10.250.0.0/16"
  type = string
}
variable "f5BigIPSubnetAZ1-MGMT" {
  description = "Subnet for Security Services AZ1"
  default = "10.250.150.0/24"
  type = string
}
variable "f5BigIPSubnetAZ1-DATA" {
  description = "Subnet for Security Services AZ1"
  default = "10.250.100.0/24"
  type = string
}
variable "f5BigIPSubnetAZ2-MGMT" {
  description = "Subnet for Security Services AZ2"
  default = "10.250.250.0/24"
  type = string
}
variable "f5BigIPSubnetAZ2-DATA" {
  description = "Subnet for Security Services AZ2"
  default = "10.250.200.0/24"
  type = string
}
variable get_address_url {
  type = string
  default = "https://api.ipify.org"
  description = "URL for getting external IP address"
}
variable get_address_request_headers {
  type = map
  default = {
    Accept = "text/plain"
  }
  description = "HTTP headers to send"
}
variable "bigipLicenseType" {
  type = string
  description = "license type BYOL or PAYG"
  default = "PAYG"
}
variable "bigip_ami_mapping" {
  description = "mapping AMIs for PAYG and BYOL"
  default = {
    "BYOL" = "BYOL-All Modules 2Boot Loc"
    "PAYG" = "PAYG-Best 10Gbps"
  }
}
variable "bigip_ec2_instance_type" {
  description = "instance type for the BIG-IP instances"
  default = "c5.4xlarge"
}
variable "bigip_version" {
  type = string
  description = "the base TMOS version to use - most recent version will be used"
  default =  "16.1"
}
variable "f5_do_version" {
  type = string
  description = "f5 declarative onboarding version (see https://github.com/F5Networks/f5-declarative-onboarding/releases/latest)"
  default = "1.21.1"
}
variable "f5_do_schema_version" {
  type = string
  description = "f5 declarative onboarding version (see https://github.com/F5Networks/f5-declarative-onboarding/releases/latest)"
  default = "1.21.0"
}
variable "f5_as3_version" {
  type = string
  description = "f5 application services version (see https://github.com/F5Networks/f5-appsvcs-extension/releases/latest)"
  default = "3.26.1"
}
variable "f5_as3_schema_version" {
  type = string
  description = "f5 application services version (see https://github.com/F5Networks/f5-appsvcs-extension/releases/latest)"
  default = "3.26.0"
}
variable "f5_ts_version" {
  type = string
  description = "f5 telemetry streaming version (see https://github.com/F5Networks/f5-declarative-onboarding/releases/latest)"
  default = "1.20.1"
}
variable "f5_ts_schema_version" {
  type = string
  description = "f5 telemetry streaming version (see https://github.com/F5Networks/f5-declarative-onboarding/releases/latest)"
  default = "1.20.1"
}