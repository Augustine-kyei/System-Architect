output "cluster_Security_Group" {
value = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.security_group_id

}

output "hsm_cluster_id" {
  value = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.cluster_id
}

