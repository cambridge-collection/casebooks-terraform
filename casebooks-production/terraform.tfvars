environment                  = "production"
project                      = "casebooks"
component                    = "cudl-data-workflows"
subcomponent                 = "cudl-transform-lambda"
destination-bucket-name      = "releases"
web_frontend_domain_name     = "casebooks-production.casebooks.lib.cam.ac.uk"
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
    "image_uri"                = "119233718832.dkr.ecr.eu-west-1.amazonaws.com/casebooks/listener@sha256:af9641da791dbc525e5e48452277d6e87efb77026f37a272ec36fc259b0f87c6"
    "queue_name"               = "CasebooksIndexTEIQueue"
    "queue_delay_seconds"      = 10
    "vpc_name"                 = "casebooks-production-casebooks-ecs-vpc"
    "subnet_names"             = ["casebooks-production-casebooks-ecs-subnet-private-a", "casebooks-production-casebooks-ecs-subnet-private-b"]
    "security_group_names"     = ["casebooks-production-casebooks-ecs-vpc-egress", "casebooks-production-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 100
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-casebooks-ecs.casebooks-production-solr"
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
cloudfront_route53_zone_id          = "Z01280312IT0HTCFLTI75"
cloudfront_distribution_name        = "casebooks-production"
cloudfront_origin_path              = "/www"
cloudfront_error_response_page_path = "/404.html"
cloudfront_default_root_object      = "index.html"

# Base Architecture
cluster_name_suffix            = "casebooks-ecs"
registered_domain_name         = "casebooks.lib.cam.ac.uk."
asg_desired_capacity           = 1 # n = number of tasks
asg_max_size                   = 1 # n + 1
asg_allow_all_egress           = true
ec2_instance_type              = "t3.large"
ec2_additional_userdata        = <<-EOF
echo 1 > /proc/sys/vm/swappiness
echo ECS_RESERVED_MEMORY=256 >> /etc/ecs/ecs.config
EOF
route53_zone_id_existing       = "Z01280312IT0HTCFLTI75"
route53_zone_force_destroy     = false
acm_certificate_arn            = "arn:aws:acm:eu-west-1:119233718832:certificate/c0ad4a7f-200f-4d79-bd83-63e101433e32"
acm_certificate_arn_us-east-1  = "arn:aws:acm:us-east-1:119233718832:certificate/328280bb-34f5-465f-b701-218acf4a24b5"
alb_enable_deletion_protection = false
alb_idle_timeout               = "900"
vpc_cidr_block                 = "10.87.0.0/22" #1024 adresses
vpc_public_subnet_public_ip    = false
cloudwatch_log_group           = "/ecs/casebooks-production"

# SOLR Worload
solr_name_suffix       = "solr"
solr_domain_name       = "casebooks-search"
solr_application_port  = 8983
solr_target_group_port = 8081
solr_ecr_repositories = {
  "casebooks/solr-api" = "sha256:827ffb2a0b43204fb357ccd8b485aa69e719b441328698ca7dc6e414c8e24ce6",
  "casebooks/solr"     = "sha256:79e9ec370e4d5ee3c1c890e0a20d40185ac1ffd96a8b0a67cd52551f8d42deb5"
}
solr_ecs_task_def_volumes     = { "solr-volume" = "/var/solr" }
solr_container_name_api       = "solr-api"
solr_container_name_solr      = "solr"
solr_health_check_status_code = "404"
solr_allowed_methods          = ["HEAD", "GET", "OPTIONS"]
solr_ecs_task_def_cpu         = 2048
solr_use_service_discovery    = true
