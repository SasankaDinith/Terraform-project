resource "aws_vpc" "my_vpc" {
    cidr_block= var.cidr
  
}

resource "aws_subnet" "subnet01" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
      
}

resource "aws_subnet" "subnet02" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
      
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  
}

resource "aws_route_table_association" "route_table_association1" {
    subnet_id = aws_subnet.subnet01.id
    route_table_id = aws_route_table.route_table.id
  
}


resource "aws_route_table_association" "route_table_association2" {
    subnet_id = aws_subnet.subnet02.id
    route_table_id = aws_route_table.route_table.id
  
}


resource "aws_security_group" "wegSg" {
  name        = "webSg"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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


resource "aws_s3_bucket" "example" {
  bucket = "sasankaterraform2026project"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.example.id
  acl    = "public-read"
}

resource "aws_instance" "vm01" {
    
    ami = "ami-0c94855ba95c71c99"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet01.id
    security_groups = [aws_security_group.wegSg.id]
    user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "vm02" {
    
    ami = "ami-0c94855ba95c71c99"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet02.id
    security_groups = [aws_security_group.wegSg.id]
    user_data = base64encode(file("userdata2.sh"))
}

resource "aws_lb" "lb" {
    name = "my-lb"
    internal = false
    load_balancer_type = "application"

    security_groups = [aws_security_group.wegSg.id]
    subnets = [aws_subnet.subnet01.id, aws_subnet.subnet02.id]

    tags ={ 
        Name = "my-lb"
    }

  
}

resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.vm01.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.vm02.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.lb.dns_name
}