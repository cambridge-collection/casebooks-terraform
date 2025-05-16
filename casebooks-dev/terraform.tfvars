environment                  = "dev"
project                      = "casebooks"
component                    = "cudl-data-workflows"
subcomponent                 = "cudl-transform-lambda"
destination-bucket-name      = "releases"
web_frontend_domain_name     = "casebooks-dev.dhcul.link"
transcriptions-bucket-name   = "unused-cul-cudl-transcriptions"
enhancements-bucket-name     = "unused-cul-cudl-data-enhancements"
source-bucket-name           = "unused-cul-cudl-data-source"
compressed-lambdas-directory = "compressed_lambdas"
lambda-jar-bucket            = "cul-cudl.mvn.cudl.lib.cam.ac.uk"

transform-lambda-bucket-sns-notifications = [

]
transform-lambda-bucket-sqs-notifications = [
  {
    "type"          = "SQS",
    "queue_name"    = "CasebooksIndexTEIQueue"
    "filter_prefix" = "solr-json/tei/"
    "filter_suffix" = ".json"
    "bucket_name"   = "releases"
  }
]
transform-lambda-information = [
  {
    "name"                     = "AWSLambda_TEI_SOLR_Listener"
    "image_uri"                = "119233718832.dkr.ecr.eu-west-1.amazonaws.com/casebooks/listener@sha256:715f737828168bb1a71decb2cf3f8f9e9565ae9d871557426c812b52fec71a3e"
    "queue_name"               = "CasebooksIndexTEIQueue"
    "queue_delay_seconds"      = 10
    "vpc_name"                 = "casebooks-dev-casebooks-ecs-vpc"
    "subnet_names"             = ["casebooks-dev-casebooks-ecs-subnet-private-a", "casebooks-dev-casebooks-ecs-subnet-private-b"]
    "security_group_names"     = ["casebooks-dev-casebooks-ecs-vpc-egress", "casebooks-dev-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-casebooks-ecs.casebooks-dev-solr"
      API_PORT = "8081"
      API_PATH = "item"
    }
  }
]
dst-efs-prefix    = "/mnt/cudl-data-releases"
dst-prefix        = "html/"
dst-s3-prefix     = ""
tmp-dir           = "/tmp/dest/"
lambda-alias-name = "LIVE"

releases-root-directory-path        = "/data"
efs-name                            = "cudl-data-releases-efs"
cloudfront_route53_zone_id          = "Z04340321BTLE5BZ141RF"
cloudfront_distribution_name        = "casebooks-dev"
cloudfront_origin_path              = "/www"
cloudfront_error_response_page_path = "/404.html"
cloudfront_default_root_object      = "index.html"

# Base Architecture
cluster_name_suffix     = "casebooks-ecs"
registered_domain_name  = "dhcul.link."
asg_desired_capacity    = 1 # n = number of tasks
asg_max_size            = 1 # n + 1
asg_allow_all_egress    = true
ec2_instance_type       = "t3.large"
ec2_additional_userdata = <<-EOF
echo 1 > /proc/sys/vm/swappiness
echo ECS_RESERVED_MEMORY=256 >> /etc/ecs/ecs.config
EOF
#route53_delegation_set_id      = "N02288771HQRX5TRME6CM"
route53_zone_id_existing       = "Z04340321BTLE5BZ141RF"
route53_zone_force_destroy     = true
alb_enable_deletion_protection = false
alb_idle_timeout               = "900"
vpc_cidr_block                 = "10.89.0.0/22" #1024 adresses
vpc_public_subnet_public_ip    = false
cloudwatch_log_group           = "/ecs/casebooks-dev"

# SOLR Worload
solr_name_suffix       = "solr"
solr_domain_name       = "casebooks-dev-search"
solr_application_port  = 8983
solr_target_group_port = 8081
solr_ecr_repositories = {
  "casebooks/solr-api" = "sha256:9f1a3ed325aab3f78c85937e33b602228e340592f937e8ba6a2029856d9028d7",
  "casebooks/solr"     = "sha256:161e5d8e144d754f5dfd8b567f31f52f95dbd1f50c327a0a085a52983fa8800b"
}
solr_ecs_task_def_volumes     = { "solr-volume" = "/var/solr" }
solr_container_name_api       = "solr-api"
solr_container_name_solr      = "solr"
solr_health_check_status_code = "404"
solr_allowed_methods          = ["HEAD", "GET", "OPTIONS"]
solr_ecs_task_def_cpu         = 2048
solr_use_service_discovery    = true
