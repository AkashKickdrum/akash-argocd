output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "jenkins_public_ip" {
  value = module.jenkins_server.jenkins_public_ip
}
