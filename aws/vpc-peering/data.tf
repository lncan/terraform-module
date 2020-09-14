data "aws_caller_identity" "zone1" {
  provider = aws.zone1
}

data "aws_region" "zone1" {
  provider = aws.zone1
}

data "aws_caller_identity" "zone0" {
  provider = aws.zone0
}
data "aws_region" "zone0" {
  provider = aws.zone0
}

data "aws_vpc" "zone1_vpc" {
  provider = aws.zone1
  filter {
    name   = "tag:Name"
    values = ["${var.zone1_prefix}_vpc"]
  }
}

data "aws_vpc" "zone0_vpc" {
  provider = aws.zone0
  filter {
    name   = "tag:Name"
    values = ["${var.zone0_prefix}_vpc"]
  }
}

data "aws_route_tables" "zone1_vpc_rts" {
  provider = aws.zone1
  vpc_id   = data.aws_vpc.zone1_vpc.id
}

data "aws_route_tables" "zone0_vpc_rts" {
  provider = aws.zone0
  vpc_id   = data.aws_vpc.zone0_vpc.id
}
