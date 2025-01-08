resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "mySg" {
  name = "websg"
  #description = "Allow traffic to EC2 instances"
  vpc_id = aws_vpc.myvpc.id

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
    Name = "Web-sg"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "rekaterraform2024project"
}

### Create IAM policy
resource "aws_iam_policy" "ec2_s3_access_policy" {
  name        = "ec2_s3_access_policy"
  description = "Permissions / Access for EC2 and S3"
  policy      = jsonencode({
    Version: "2012-10-17",
    Statement: [
        {
            Action: "ec2:*",
            Effect: "Allow",
            Resource: "*"
        },
        {
            Action: "s3:*",
            Effect: "Allow",
            Resource: "*"
      }
      ]
    })
}

### Create IAM role
resource "aws_iam_role" "ec2_to_s3_role" {
  name = "ec2_to_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "EC2ToS3Access"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

### Attach IAM policy to IAM role
resource "aws_iam_policy_attachment" "policy_attach" {
  name       = "example_policy_attachment"
  roles      = [aws_iam_role.ec2_to_s3_role.name]
  policy_arn = aws_iam_policy.ec2_s3_access_policy.arn
}

### Create instance profile using role
resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "iam_instance_profile"
  role = aws_iam_role.ec2_to_s3_role.name
}

### Create EC2 instance and attache IAM role
resource "aws_instance" "ec2_instance" {
  instance_type        = var.ec2_instance_type
  ami                  = var.image_id
  vpc_security_group_ids = [aws_security_group.mySg.id]
  subnet_id            = aws_subnet.sub1.id
  iam_instance_profile = aws_iam_instance_profile.iam_instance_profile.name
}
