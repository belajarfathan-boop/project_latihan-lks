output "rds_endpoint" {
  value = aws_db_instance.lks_rds.endpoint
}
output "redis_endpoint" {
  value = aws_elasticache_cluster.lks_redis.cache_nodes[0].address
}
output "alb_dns_name" {
  value = aws_lb.lks_alb.dns_name
} 