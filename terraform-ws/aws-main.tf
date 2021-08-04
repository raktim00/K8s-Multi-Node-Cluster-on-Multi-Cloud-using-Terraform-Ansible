resource "aws_vpc" "aws_k8s_vnet" {
  cidr_block = "10.2.0.0/16"
  tags = {
    Name = "aws-k8s-network"
  }
}

resource "aws_internet_gateway" "aws_k8s_igw" {

  depends_on = [
    aws_vpc.aws_k8s_vnet
  ]

  vpc_id = aws_vpc.aws_k8s_vnet.id
  tags = {
    Name = "aws-k8s-igw"
  }
}

resource "aws_subnet" "aws_k8s_subnet" {

  depends_on = [
    aws_vpc.aws_k8s_vnet
  ]

  vpc_id     = aws_vpc.aws_k8s_vnet.id
  availability_zone = "ap-south-1b"
  cidr_block = "10.2.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "aws-k8s-subnet"
  }
}

resource "aws_route_table" "aws_k8s_rt" {

  depends_on = [
    aws_vpc.aws_k8s_vnet,
    aws_internet_gateway.aws_k8s_igw
  ]

  vpc_id = aws_vpc.aws_k8s_vnet.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_k8s_igw.id
  }
  tags = {
    Name = "aws-k8s-rt"
  }
}

resource "aws_route_table_association" "aws_k8s_subnet_rt" {

  depends_on = [
    aws_subnet.aws_k8s_subnet,
    aws_route_table.aws_k8s_rt
  ]

  subnet_id      = aws_subnet.aws_k8s_subnet.id
  route_table_id = aws_route_table.aws_k8s_rt.id
}

resource "aws_security_group" "aws_k8s_sg" {

  depends_on = [
    aws_vpc.aws_k8s_vnet
  ]

  name        = "aws-allowall-sg"
  description = "Allow All inbound TCP traffic"
  vpc_id      = aws_vpc.aws_k8s_vnet.id

  ingress {
    description      = "Allow All TCP"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "aws_k8s_key" {
  key_name   = "aws-k8s-key"
  public_key = file("../k8s-multi-cloud-key-public.pub")
  }

resource "aws_instance" "aws_k8s_master" {

  depends_on = [
    aws_key_pair.aws_k8s_key,
    aws_subnet.aws_k8s_subnet,
    aws_security_group.aws_k8s_sg,
  ]

  ami = "ami-0e6837d3d816a2ac6"
  instance_type = "t2.medium"
  key_name = aws_key_pair.aws_k8s_key.key_name
  vpc_security_group_ids = [ "${aws_security_group.aws_k8s_sg.id}" ]
  subnet_id = aws_subnet.aws_k8s_subnet.id
  tags = {
    "Name" = "aws-k8s-master"
  }
}