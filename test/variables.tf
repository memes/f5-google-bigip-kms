variable "name" {
  type     = string
  nullable = false
  default  = "f5-google-bigip-kms"
}

variable "project_id" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
  default  = "us-west1"
}

variable "test_cidrs" {
  type    = list(any)
  default = []
}

variable "labels" {
  type    = map(string)
  default = {}
}
