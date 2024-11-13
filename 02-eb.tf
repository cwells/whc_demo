resource "aws_iam_role" "beanstalk_service" {
  name = "beanstalk_role"

  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": "" 
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "beanstalk_log_attach" {
  role       = aws_iam_role.beanstalk_service.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "beanstalk_iam_instance_profile" {
  name = "beanstalk_iam_instance_profile"
  role = aws_iam_role.beanstalk_service.name
}

resource "aws_elastic_beanstalk_application" "whc_app" {
  name        = "whc-app-dev"
  description = "World Heritage Sites demo app"
}

resource "aws_elastic_beanstalk_application_version" "whc_app_ebs_version" {
  name        = "whc-app-ebs-version-${local.release}"
  application = aws_elastic_beanstalk_application.whc_app.name
  bucket      = aws_s3_bucket.whc_app_ebs.id
  key         = aws_s3_object.whc_app_deployment.id
}

resource "aws_elastic_beanstalk_environment" "dev_env" {
  name         = "whc-app-dev-env"
  application  = aws_elastic_beanstalk_application.whc_app.name
  version_label = aws_elastic_beanstalk_application_version.whc_app_ebs_version.name
  cname_prefix = "whc-app"
  solution_stack_name = "64bit Amazon Linux 2023 v4.4.0 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_iam_instance_profile.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "True"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "DisableIMDSv1"
    value     = "true"
  }  

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeType"
    value     = "gp3"
  }  
}

output "environment" {
  value = aws_elastic_beanstalk_environment.dev_env.cname
}