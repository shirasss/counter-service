resource "aws_efs_file_system" "counter" {
  encrypted = true
  tags = {
    Name = "counter-efs"
  }
}

resource "aws_efs_mount_target" "efs_targets" {
  for_each = {
    "a" = aws_subnet.private_subnet_a.id
    "b" = aws_subnet.private_subnet_b.id
  }

  file_system_id  = aws_efs_file_system.counter.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name   = "efs_sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }
}

