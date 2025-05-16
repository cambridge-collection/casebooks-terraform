resource "aws_cloudfront_function" "casebooks" {
  name                         = "${local.environment}-clean_urls"
  runtime                      = "cloudfront-js-2.0"
  comment                      = "clean-and-redirect"
  publish                      = true
  key_value_store_associations = [aws_cloudfront_key_value_store.viewer.arn]
  code                         = file("${path.module}/templates/casebooks/main-frontend.js.ttfpl")
}

resource "aws_cloudfront_function" "search" {
  name                         = "${local.environment}-search-api"
  runtime                      = "cloudfront-js-2.0"
  comment                      = "search api frontend"
  publish                      = true
  key_value_store_associations = [aws_cloudfront_key_value_store.viewer.arn]
  code                         = file("${path.module}/templates/casebooks/search-frontend.js.ttfpl")
}

resource "aws_cloudfront_key_value_store" "viewer" {
  name = "${local.environment}-cudl-viewer"
}

resource "aws_cloudfrontkeyvaluestore_key" "domain" {
  key_value_store_arn = aws_cloudfront_key_value_store.viewer.arn
  key                 = "domain"
  value               = "dhcul.link"
  # The value should be generated from registered_domain_name (with a replace to remove trailing period)
}

resource "aws_cloudfrontkeyvaluestore_key" "privateSite" {
  key_value_store_arn = aws_cloudfront_key_value_store.viewer.arn
  key                 = "privateSite"
  value               = true
}
