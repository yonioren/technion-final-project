variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "aws_session_token" {}
variable "ec2_image_id_public" {}
variable "ec2_image_id_apps" {}
variable "instance_type" {}

locals {
  ansible_install_user_data = "${path.root}/../ansible/user_data.sh"
}
