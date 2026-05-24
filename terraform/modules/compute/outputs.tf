output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}

output "backend_public_dns" {
  value = aws_instance.backend.public_dns
}

output "backend_instance_id" {
  value = aws_instance.backend.id
}
