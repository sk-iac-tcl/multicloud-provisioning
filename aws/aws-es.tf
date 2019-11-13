data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

variable "domain" {
  default = "tcl-aws-es"
}

resource "aws_elasticsearch_domain" "tcl-aws-es" {
  domain_name           = "${var.domain}"
  elasticsearch_version = "7.1"

  cluster_config {
    instance_type = "t2.medium.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 30
  }

  snapshot_options {
    automated_snapshot_start_hour = 18
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "es:*",
      "Principal": "*",
      "Effect": "Allow",
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain}/*"
    }
  ]
}
CONFIG

  tags = {
    Domain = "tcl-aws-es"
  }

}
