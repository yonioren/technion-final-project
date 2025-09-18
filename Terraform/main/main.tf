module "KP" {
  source        = "../modules/keypair"
  providers     = { aws = aws }
  key_name      = "KP"
}

resource "local_sensitive_file" "keypair_KP" {
  filename  = "${path.module}/${module.KP.key_name}.pem"
  content   = "${module.KP.private_key_pem}"
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

module "vpc" {
  source            = "../modules/vpc"
  providers         = { aws = aws }
  vpc_name          = "VPC"
  net_prefix        = "172.20"
  Control_Subnet_AZ = "us-east-1a"
  Managed_Subnet1_AZ = "us-east-1b"
  Managed_Subnet2_AZ = "us-east-1c"
  #source_ip         = var.source_ip
  source_ip = chomp(data.http.myip.response_body)
}

module "EC2_Control" {
  source     = "../modules/ec2"
  providers  = { aws = aws }
  depends_on = [  module.ec2_app2 ,
                  module.ec2_app1,
                  module.KP ]
                  
  EC2_Name   = "Control_EC2"
  #private_ip = "${module.vpc.Control_Subnet_Prefix}.11"    #Changed from 111 to 11
  type       = var.instance_type
  ami        = var.ec2_image_id_public
  sg_id      = module.vpc.Control_sg_id
  subnet_id  = module.vpc.Control_subnet_id
  key_name   = module.KP.key_name
  #user_data  = local.ansible_install_user_data
  user_data = templatefile(local.ansible_install_user_data, {
        app1_ip = module.ec2_app1.Private_IP
        app2_ip = module.ec2_app2.Private_IP
      })
  }

module "ec2_app1" {
  source      = "../modules/ec2"
  providers   = { aws = aws }
  EC2_Name    = "app1"
  #private_ip  = "${module.vpc.Managed_Subnet1_Prefix}.6${count.index+1}"   # changed IP to 60.61 + 60.62
  type        = var.instance_type
  ami         = var.ec2_image_id_apps
  sg_id       = module.vpc.Managed_sg_id
  subnet_id   = module.vpc.Managed_subnet1_id
  key_name    = module.KP.key_name
  }

module "ec2_app2" {
  source      = "../modules/ec2"
  providers   = { aws = aws }
  EC2_Name    = "app2"
  #private_ip  = "${module.vpc.Managed_Subnet2_Prefix}.6${count.index+1}"   # changed IP to 60.61 + 60.62
  type        = var.instance_type
  ami         = var.ec2_image_id_apps
  sg_id       = module.vpc.Managed_sg_id
  subnet_id   = module.vpc.Managed_subnet2_id
  key_name    = module.KP.key_name
  }
