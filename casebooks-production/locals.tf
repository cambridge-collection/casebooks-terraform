locals {
  environment      = lower(join("-", [var.project, var.environment]))
  base_name_prefix = join("-", compact([local.environment, var.cluster_name_suffix]))
  default_tags = {
    Environment  = title(var.environment)
    Project      = var.project
    Component    = var.component
    Subcomponent = var.subcomponent
    Deployment   = title(local.environment)
    Source       = "https://github.com/cambridge-collection/cudl-terraform"
    terraform    = true
  }
  additional_lambda_variables = {
    AWS_DATA_ENHANCEMENTS_BUCKET = "${local.environment}-cudl-data-enhancements"
    AWS_DATA_SOURCE_BUCKET       = "${local.environment}-cudl-data-source"
    AWS_OUTPUT_BUCKET            = "${local.environment}-cudl-data-releases"
  }
  enhancements_lambda_variables = {
    AWS_CUDL_DATA_SOURCE_BUCKET = "${local.environment}-cudl-data-source"
    AWS_OUTPUT_BUCKET           = "${local.environment}-cudl-data-source"
  }
  solr_ecs_task_def_memory = data.aws_ec2_instance_type.asg.memory_size - 1024

  # Matches the incoming viewer URI, before the clean_urls function rewrites it.
  # /search is a live query endpoint that must stay dynamic. /search* would also catch /searching/what-am-i-searching.
  cloudfront_ordered_cache_behaviors = [
    {
      path_pattern                 = "/search"
      cache_policy_name            = "Managed-CachingDisabled"
      response_headers_policy_name = aws_cloudfront_response_headers_policy.no_store.name
    },
    {
      path_pattern                 = "/search/*"
      cache_policy_name            = "Managed-CachingDisabled"
      response_headers_policy_name = aws_cloudfront_response_headers_policy.no_store.name
    },
  ]
}
