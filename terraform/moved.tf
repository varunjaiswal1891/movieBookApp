moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}

moved {
  from = aws_subnet.public[0]
  to   = module.network.aws_subnet.public[0]
}

moved {
  from = aws_subnet.public[1]
  to   = module.network.aws_subnet.public[1]
}

moved {
  from = aws_subnet.private[0]
  to   = module.network.aws_subnet.private[0]
}

moved {
  from = aws_subnet.private[1]
  to   = module.network.aws_subnet.private[1]
}

moved {
  from = aws_internet_gateway.main
  to   = module.network.aws_internet_gateway.main
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table_association.public[0]
  to   = module.network.aws_route_table_association.public[0]
}

moved {
  from = aws_route_table_association.public[1]
  to   = module.network.aws_route_table_association.public[1]
}

moved {
  from = aws_iam_role.backend
  to   = module.compute.aws_iam_role.backend
}

moved {
  from = aws_iam_role_policy.backend_s3
  to   = module.compute.aws_iam_role_policy.backend_s3
}

moved {
  from = aws_iam_role_policy_attachment.backend_codedeploy[0]
  to   = module.compute.aws_iam_role_policy_attachment.backend_codedeploy[0]
}

moved {
  from = aws_iam_instance_profile.backend
  to   = module.compute.aws_iam_instance_profile.backend
}

moved {
  from = aws_key_pair.backend
  to   = module.compute.aws_key_pair.backend
}

moved {
  from = aws_instance.backend
  to   = module.compute.aws_instance.backend
}
