output "public_vm_ip" {
  value = module.EC2_Control.Public_IP
}

output "private_apps201" {
  value = module.ec2_app1.Private_IP
}

output "private_apps202" {
  value = module.ec2_app2.Private_IP
}

# output "LB_DNS" {
#   value = aws_lb.external-alb.dns_name
# }