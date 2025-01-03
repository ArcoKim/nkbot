resource "aws_s3_bucket" "static" {
  bucket_prefix = "nkbot-statics-"
  force_destroy = true
}

resource "aws_s3_bucket" "data" {
  bucket_prefix = "nkbot-data-"
  force_destroy = true
}

resource "aws_s3_object" "static" {
  bucket   = aws_s3_bucket.static.id
  for_each = fileset("static/", "**/*.*")

  key    = each.value
  source = "static/${each.value}"

  content_type = lookup(local.content_type_map, split(".", each.value)[1], "text/html")
  etag         = filemd5("static/${each.value}")
}

resource "aws_s3_object" "data" {
  bucket   = aws_s3_bucket.data.id
  for_each = fileset("data/", "**/*.*")

  key    = each.value
  source = "data/${each.value}"

  content_type = "application/pdf"
  source_hash  = filemd5("data/${each.value}")
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}

data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.static.arn,
      "${aws_s3_bucket.static.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}