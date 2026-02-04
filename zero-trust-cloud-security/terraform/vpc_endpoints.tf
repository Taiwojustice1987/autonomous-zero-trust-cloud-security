############################################
# S3 Gateway VPC Endpoint (NO NAT)
# Lets private subnets reach S3 privately
############################################
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.zero_trust_vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_rt.id
  ]

  tags = {
    Name = "zero-trust-s3-gateway-endpoint"
  }
}
