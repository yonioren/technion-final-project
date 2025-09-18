# Create key pair for all the machines
module "KP" {
  source        = "../modules/keypair"
  providers     = { aws = aws }
  key_name      = "KP"
}

# Keep offline copy of the prv_key for connection purposes
resource "local_sensitive_file" "keypair_KP" {
  filename  = "${path.module}/${module.KP.key_name}.pem"
  content   = "${module.KP.private_key_pem}"
}

# Get my own private IP from the net
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# Create all network aspects of the env
module "vpc" {
  source            = "../modules/vpc"
  providers         = { aws = aws }
  vpc_name          = "VPC"
  net_prefix        = "172.20"
  Control_Subnet_AZ = "us-east-1a"
  Managed_Subnet1_AZ = "us-east-1b"
  Managed_Subnet2_AZ = "us-east-1c"
  source_ip = chomp(data.http.myip.response_body)
  LB_SG_ID = aws_security_group.web-sg.id
}

# Creation of the ansible machine
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

  # Hey, guess what. We are using outputs of the module. YAY!
  user_data = templatefile(local.ansible_install_user_data, {
        app1_ip = module.ec2_app1.Private_IP
        app2_ip = module.ec2_app2.Private_IP
      })
  }

# 1st app machine
module "ec2_app1" {
  source      = "../modules/ec2"
  providers   = { aws = aws }
  EC2_Name    = "app1"
  type        = var.instance_type
  ami         = var.ec2_image_id_apps
  sg_id       = module.vpc.Managed_sg_id
  subnet_id   = module.vpc.Managed_subnet1_id
  key_name    = module.KP.key_name
  }

# 2nd app machine
module "ec2_app2" {
  source      = "../modules/ec2"
  providers   = { aws = aws }
  EC2_Name    = "app2"
  type        = var.instance_type
  ami         = var.ec2_image_id_apps
  sg_id       = module.vpc.Managed_sg_id
  subnet_id   = module.vpc.Managed_subnet2_id
  key_name    = module.KP.key_name
  }
