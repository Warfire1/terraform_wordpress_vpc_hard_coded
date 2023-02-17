########
   #PROVIDERS
########

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
  version = "~> 4.0"
}

resource "aws_internet_gateway" "wordpress_igw" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "wordpress_igw"
  }
}

resource "aws_route_table" "wordpress-rt" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "wordpress-rt"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress_igw.id
  }
}

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public_a"
  }
} 

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public_b"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "public_c"
  }
} 

resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_b"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id = aws_vpc.wordpress-vpc.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "private_c"
  }
}  

# Public Subnet Route Table Association
resource "aws_route_table_association" "public_subnet_association_1" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.wordpress-rt.id
}
resource "aws_route_table_association" "public_subnet_association_2" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.wordpress-rt.id
}
resource "aws_route_table_association" "public_subnet_association_3" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.wordpress-rt.id
}



########
   #VPC
########

resource "aws_vpc" "wordpress-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "wordpress-vpc"
  }
}




# resource "aws_route" "internet_access" {
#   route_table_id = aws_route_table.wordpress.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id = aws_internet_gateway.wordpress_igw.id
# }


resource "aws_security_group" "vpc_sg" {
  name = "vpc_sg"
  description = "Allow HTTP, HTTPS, and SSH access"
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "vpc_sg"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
}

resource "aws_security_group" "mysql-sg" {
  name = "mysql-sg"
  description = "Allow MySQL traffic via Terraform"
  vpc_id = aws_vpc.wordpress-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [
      aws_security_group.vpc_sg.id
    ]
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "mysql-sg"
  }
}

resource "aws_instance" "wordpress-ec2" {
  ami           = "ami-0aa7d40eeae50c9a9"
  instance_type = "t2.medium"
  key_name      = "gang-bang"
  vpc_security_group_ids = [aws_security_group.vpc_sg.id]
  associate_public_ip_address = true
  user_data = "${file("db-user-data.sh")}"

  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "wordpress-ec2"
  }

  
}



resource "aws_db_instance" "mysql" {
  db_name                     = "db"
  identifier                  = "mysql"
  engine                      = "mysql"
  engine_version             = "5.7"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  storage_type               = "gp2"
  vpc_security_group_ids     = [aws_security_group.mysql-sg.id]
  skip_final_snapshot        = true 
  publicly_accessible        = false
  username                   = "admin"
  password                   = "adminadmin"
  db_subnet_group_name       = aws_db_subnet_group.private.name  
  tags = {
    Name = "mysql"
  }
}



resource "aws_db_subnet_group" "private" {
  name       = "mysql-private-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
}


