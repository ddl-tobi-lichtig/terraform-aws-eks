resource "aws_route_table" "public" {
  for_each = local.public_subnets
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  vpc_id = local.vpc_id
  tags = {
    "Name"                                   = each.value.name,
    "kubernetes.io/role/elb"                 = "1",
    "kubernetes.io/cluster/${var.deploy_id}" = "shared",
  }

}

resource "aws_route_table_association" "public" {
  for_each       = local.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

locals {
  private_public_map = zipmap(keys(local.private_subnets), keys(local.public_subnets))
}

resource "aws_route_table" "private" {
  for_each = local.private_subnets
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[local.private_public_map[each.key]].id
  }
  vpc_id = local.vpc_id
  tags = {
    "Name"                                   = each.value.name,
    "kubernetes.io/role/internal-elb"        = "1",
    "kubernetes.io/cluster/${var.deploy_id}" = "shared",
  }
}

resource "aws_route_table_association" "private" {
  for_each       = local.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
