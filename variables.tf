variable "region" {
  default = "us-east-1"
}
variable "azs" {
  type = "list"
  default = ["us-east-1a", "us-east-1b"]
}
variable "env" {}
variable "instance_type" {
  type = "map"
  default = {
    dev = "t2.micro"
    prod = "t2.medium"
  }
}
variable "cidr" {
  type = "list"
  default = ["0.0.0.0/0"]
}