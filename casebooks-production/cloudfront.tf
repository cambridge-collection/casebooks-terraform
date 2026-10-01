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

# No AWS managed response headers policy sets Cache-Control, so /search needs a custom one.
resource "aws_cloudfront_response_headers_policy" "no_store" {
  name    = "${local.environment}-no-store"
  comment = "Prevents browser and proxy caching"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "no-store"
      override = true
    }
  }
}

# Managed-CachingOptimized with a one-year default TTL, which applies because the S3 objects carry no Cache-Control.
resource "aws_cloudfront_cache_policy" "one_year" {
  name        = "${local.environment}-caching-one-year"
  comment     = "Caches at the edge for one year"
  min_ttl     = 1
  default_ttl = 31536000
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "max_age_one_day" {
  name    = "${local.environment}-max-age-one-day"
  comment = "Limits browser caching to 24 hours"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "max-age=86400"
      override = true
    }
  }
}

resource "aws_cloudfrontkeyvaluestore_key" "domain" {
  key_value_store_arn = aws_cloudfront_key_value_store.viewer.arn
  key                 = "domain"
  value               = "casebooks.lib.cam.ac.uk"
  # The value should be generated from registered_domain_name (with a replace to remove trailing period)
}

resource "aws_cloudfrontkeyvaluestore_key" "privateSite" {
  key_value_store_arn = aws_cloudfront_key_value_store.viewer.arn
  key                 = "privateSite"
  value               = false
}
