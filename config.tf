terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.56.1"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.3.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

provider "opensearch" {
  url         = aws_opensearchserverless_collection.kb.collection_endpoint
  aws_region  = "ap-northeast-2"
  healthcheck = false
}

data "aws_caller_identity" "main" {}
data "aws_partition" "main" {}

locals {
  content_type_map = {
    "js"   = "text/javascript"
    "html" = "text/html"
    "css"  = "text/css"
  }
  account_id = data.aws_caller_identity.main.account_id
  partition  = data.aws_partition.main.partition
}