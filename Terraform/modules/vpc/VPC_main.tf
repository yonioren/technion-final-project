
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC with predefined cidr
resource "aws_vpc" "VPC" {
  cidr_block = "${var.net_prefix}.0.0/16"
  tags = {
    Name =  var.vpc_name
  }
}

# sub for ansible
# Public with access to privates
resource "aws_subnet" "Control" {
  vpc_id            = aws_vpc.VPC.id
  availability_zone = var.Control_Subnet_AZ
  cidr_block        = "${var.net_prefix}.10.0/24"   #Changed from 111 to 10
  map_public_ip_on_launch = true
    tags = {
    Name =  "${var.vpc_name}-Control-Subnet"
    }
  }

# Subnet for app1
resource "aws_subnet" "Managed1" {
  vpc_id            = aws_vpc.VPC.id
  availability_zone = var.Managed_Subnet2_AZ
  cidr_block = "${var.net_prefix}.50.0/24"    #Changed from .222 to .50 + .60
    tags = {
    Name =  "${var.vpc_name}-Managed-Subnet1"
    }
}

# Subnet for app2
resource "aws_subnet" "Managed2" {
  vpc_id            = aws_vpc.VPC.id
  availability_zone = var.Managed_Subnet1_AZ
  cidr_block = "${var.net_prefix}.60.0/24"
    tags = {
    Name =  "${var.vpc_name}-Managed-Subnet2"
    }
}

# Public subnet for LB - first
resource "aws_subnet" "LB_PUB1" {
  vpc_id            = aws_vpc.VPC.id
  availability_zone = var.Managed_Subnet1_AZ
  cidr_block        = "${var.net_prefix}.70.0/24"   #Changed from 111 to 10
  map_public_ip_on_launch = true
    tags = {
    Name =  "${var.vpc_name}-LB-PUB1-Subnet"
    }
  }

# Public subnet for LB - second
resource "aws_subnet" "LB_PUB2" {
  vpc_id            = aws_vpc.VPC.id
  availability_zone = var.Managed_Subnet2_AZ
  cidr_block        = "${var.net_prefix}.80.0/24"   #Changed from 111 to 10
  map_public_ip_on_launch = true
    tags = {
    Name =  "${var.vpc_name}-LB-PUB2-Subnet"
    }
  }

# IGW for internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC.id
    tags = {
    Name =  "${var.vpc_name}-Ansible-IGW"
    }
}

# Ansible should be world accessible for SSH
resource "aws_security_group" "Control_SG" {
  name        = "SG for Control Subnet"
  description = "Allow SSH/HTTP from specific IP and from VPC, Allow Internet outband"
  vpc_id      = aws_vpc.VPC.id
  tags = {
    Name  = "SG for Control Subnet"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.source_ip}/32", aws_vpc.VPC.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# App hosts should be SSH accessible from ansible and WEB application accessible from LB
resource "aws_security_group" "Managed_SG" {
  name        = "Internal_app_SG"
  description = "Allow SSH only from VPC, WEB from LB and full internet outbound"
  vpc_id      = aws_vpc.VPC.id
  tags = {
    Name  = "Internal_APP_SG"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.VPC.cidr_block]
  }
  ingress {
    from_port   = 8666
    to_port     = 8666
    protocol    = "tcp"
    security_groups = [var.LB_SG_ID]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Route table to internet
resource "aws_route_table" "Internet_Route" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name  = "Internet_Route"
  }

}

# Route to internet for public subnets
resource "aws_route_table_association" "Control_Subnet_RTA" {
  subnet_id      = aws_subnet.Control.id
  route_table_id = aws_route_table.Internet_Route.id
}

resource "aws_route_table_association" "LB_Subnet1_RTA" {
  subnet_id      = aws_subnet.LB_PUB1.id
  route_table_id = aws_route_table.Internet_Route.id
}

resource "aws_route_table_association" "LB_Subnet2_RTA" {
  subnet_id      = aws_subnet.LB_PUB2.id
  route_table_id = aws_route_table.Internet_Route.id
}

# Define NAT for private subnets on public subnet with external IP
resource "aws_eip" "NAT_EIP" {
  
}

resource "aws_nat_gateway" "gw" {
  depends_on = [ aws_route_table_association.Control_Subnet_RTA ]
  subnet_id  = aws_subnet.Control.id
  allocation_id = aws_eip.NAT_EIP.id
}

# Define routes for private subnets via the NAT
resource "aws_route_table" "Route_to_NAT" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name  = "NAT_Internet_Routing"
  }

}

resource "aws_route_table_association" "Managed_Subnet1_RTA" {   #Updated RTAs for 2 managed subnets
  subnet_id      = aws_subnet.Managed1.id
  route_table_id = aws_route_table.Route_to_NAT.id
}

resource "aws_route_table_association" "Managed_Subnet2_RTA" {
  subnet_id      = aws_subnet.Managed2.id
  route_table_id = aws_route_table.Route_to_NAT.id
}
