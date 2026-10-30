resource "aws_wafv2_ip_set" "solr_allow" {
  name               = "${module.solr.name_prefix}-UCAM"
  provider           = aws.us-east-1
  description        = "Managed by Terraform"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.waf_ip_allow_list_addresses
}

resource "aws_wafv2_web_acl" "solr" {
  name        = "${module.solr.name_prefix}-waf-web-acl"
  provider    = aws.us-east-1
  description = "Managed by Terraform"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${module.solr.name_prefix}-waf-web-acl-no-rule"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 0

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # Count rather than allow: allow is terminating and would skip the rate limiting and /items origin rules.
        rule_action_override {
          name = "SizeRestrictions_QUERYSTRING"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${module.solr.name_prefix}-rate-limiting"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = 600
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300

        # Exempt via scope-down rather than an allow rule, which would bypass the /items restriction.
        scope_down_statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.solr_allow.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${module.solr.name_prefix}-rate-limiting"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${module.solr.name_prefix}-allow-items"
    priority = 4

    action {
      allow {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            positional_constraint = "STARTS_WITH"
            search_string         = "/items"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        statement {
          # A single origin is matched directly: or_statement needs two or more statements.
          dynamic "byte_match_statement" {
            for_each = length(var.solr_allowed_origins) == 1 ? var.solr_allowed_origins : []
            content {
              positional_constraint = "EXACTLY"
              search_string         = byte_match_statement.value
              field_to_match {
                single_header {
                  name = "origin"
                }
              }
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }

          dynamic "or_statement" {
            for_each = length(var.solr_allowed_origins) > 1 ? [1] : []
            content {
              dynamic "statement" {
                for_each = var.solr_allowed_origins
                content {
                  byte_match_statement {
                    positional_constraint = "EXACTLY"
                    search_string         = statement.value
                    field_to_match {
                      single_header {
                        name = "origin"
                      }
                    }
                    text_transformation {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${module.solr.name_prefix}-allow-items"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${module.solr.name_prefix}-allow-robots-txt"
    priority = 5

    action {
      allow {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            positional_constraint = "EXACTLY"
            search_string         = "/robots.txt"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        statement {
          byte_match_statement {
            positional_constraint = "EXACTLY"
            search_string         = "GET"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${module.solr.name_prefix}-allow-robots-txt"
      sampled_requests_enabled   = true
    }
  }

}
