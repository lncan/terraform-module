# Providers are required because of cross-region
provider "aws" {
  alias = "zone1"
}

provider "aws" {
  alias = "zone0"
}

locals {
  zone1_region           = data.aws_region.zone1.name
  zone0_region           = data.aws_region.zone0.name

  same_region            = data.aws_region.zone1.name == data.aws_region.zone0.name
  same_account           = data.aws_caller_identity.zone1.account_id == data.aws_caller_identity.zone0.account_id
  same_acount_and_region = local.same_region && local.same_account
}

##########################
# VPC peering connection #
##########################
resource "aws_vpc_peering_connection" "zone1_peers_zone0" {
  provider      = aws.zone1
  peer_owner_id = data.aws_caller_identity.zone0.account_id
  peer_vpc_id   = data.aws_vpc.zone0_vpc.id
  vpc_id        = data.aws_vpc.zone1_vpc.id
  peer_region   = data.aws_region.zone0.name
  tags = {
    Name = var.peering_tag
  }
}

######################################
# VPC peering accepter configuration #
######################################
resource "aws_vpc_peering_connection_accepter" "peer_accepter" {
  provider                  = aws.zone0
  vpc_peering_connection_id = aws_vpc_peering_connection.zone1_peers_zone0.id
  auto_accept               = var.auto_accept_peering
  tags = {
    Name = var.peering_tag
  }
}

#######################
# VPC peering options #
#######################
resource "aws_vpc_peering_connection_options" "requester" {
  provider                  = aws.zone1
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer_accepter.id

  requester {
    allow_remote_vpc_dns_resolution  = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  provider                  = aws.zone0
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer_accepter.id

  accepter {
    allow_remote_vpc_dns_resolution  = true
  }
}

###################
# zone1 VPC Routes #
###################
resource "aws_route" "zone1_routes_region" {
  provider                  = aws.zone1
  count                     = length(data.aws_route_tables.zone1_vpc_rts.ids)
  route_table_id            = tolist(data.aws_route_tables.zone1_vpc_rts.ids)[count.index]
  destination_cidr_block    = data.aws_vpc.zone0_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.zone1_peers_zone0.id
}

###################
# Peer VPC Routes #
###################
resource "aws_route" "zone0_routes_region" {
  provider                  = aws.zone0
  count                     = length(data.aws_route_tables.zone0_vpc_rts.ids)
  route_table_id            = tolist(data.aws_route_tables.zone0_vpc_rts.ids)[count.index]
  destination_cidr_block    = data.aws_vpc.zone1_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.zone1_peers_zone0.id
}
