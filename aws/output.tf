output "ElasticSearch_Endpoint" {
  description = "Elasticsearch Enpoint"
  value = "${aws_elasticsearch_domain.tcl-aws-es.endpoint}"
}

output "Kibana_Endpoint" {
  description = "Kibana Enpoint"
  value = "${aws_elasticsearch_domain.tcl-aws-es.kibana_endpoint}"
}