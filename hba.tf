
# define the private key.
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

# define the certificate registration.
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}

# define the certificate
resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = var.sub_domain
  dns_challenge {
    provider = "route53"
  }
}

# define the site cetificate iam register
resource "aws_iam_server_certificate" "site_cert" {
  name_prefix       = "vault-cert-"
  certificate_body  =  acme_certificate.certificate.certificate_pem
  private_key       = acme_certificate.certificate.private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}

# define the load balancer
resource "aws_elb" "balancer" {
  name = "balancer"
  security_groups = [aws_security_group.elb_ipsec.id]
  subnets = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = aws_iam_server_certificate.site_cert.arn
  }

  tags = {
    Name = "vault load balancer"
  }
}

#define the load balancer ipsec
resource "aws_security_group" "elb_ipsec" {
  vpc_id = aws_vpc.vpc.id
  name = "elb_ipsec"
  description = "vault load balancer ipsec"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault load ipsec"
  }

}

# locate the zone
data "aws_route53_zone" "domain" {
  name = var.domain
}

# define the host zone record
resource "aws_route53_record" "record" {
  name = acme_certificate.certificate.certificate_domain
  type = "A"
  zone_id = data.aws_route53_zone.domain.zone_id
  alias {
    evaluate_target_health = true
    name = aws_elb.balancer.dns_name
    zone_id = aws_elb.balancer.zone_id
  }
}

# define the vault launch instance
resource "aws_launch_configuration" "vault" {
  name = "vault server"
  key_name = var.key_name
  enable_monitoring = false
  image_id = "ami-039a49e70ea773ffc"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.private_ipsec.id]
  associate_public_ip_address = false
  user_data = file("${path.module}/scripts/user_data.sh")
  placement_tenancy = "default"

  root_block_device {
    volume_size = "20"
    volume_type = "gp2"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

}

# define the auto scaling policy

resource "aws_autoscaling_group" "master_scaling" {
  name = "vault hpa"
  max_size = 2
  min_size = 1
  launch_configuration = aws_launch_configuration.vault.name
  vpc_zone_identifier = [aws_subnet.private_subnet.id]
  load_balancers = [aws_elb.balancer.id]
  health_check_type = "ELB"

  lifecycle {
    create_before_destroy = true
  }
}

