resource "aws_security_group" "web-sg" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "web-sg"
  }
}

resource "aws_lb" "external-alb" {
  name               = "External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [module.vpc.Managed_subnet1_id, module.vpc.Managed_subnet1_id]
}
resource "aws_lb_target_group" "target_elb" {
  name     = "ALB-TG"
  port     = 8666
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  health_check {
    path     = "/"
    port     = 8666
    protocol = "HTTP"
  }
}
resource "aws_lb_target_group_attachment" "app1_to_target" {
  target_group_arn = aws_lb_target_group.target_elb.arn
  target_id        = module.ec2_app1.instance_id
  port             = 8666
}
resource "aws_lb_target_group_attachment" "app2_to_target" {
  target_group_arn = aws_lb_target_group.target_elb.arn
  target_id        = module.ec2_app2.instance_id
  port             = 8666
}
resource "aws_lb_listener" "listener_elb" {
  load_balancer_arn = aws_lb.external-alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_elb.arn
  }
}