# Create an IAM role for Elastic Beanstalk to assume for EC2 instances.
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


# Attach managed IAM policy to the Beanstalk service role to grant access to S3 and Cloudwatch.
resource "aws_iam_role_policy_attachment" "beanstalk_log_attach" {
  role       = aws_iam_role.beanstalk_service.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Create an IAM instance profile for the Beanstalk service role.
resource "aws_iam_instance_profile" "beanstalk_iam_instance_profile" {
  name = "beanstalk_iam_instance_profile"
  role = aws_iam_role.beanstalk_service.name
}

# Define the Elastic Beanstalk application as a container for the environment and application versions.
resource "aws_elastic_beanstalk_application" "whc_app" {
  name        = "whc-app-dev"
  description = "World Heritage Sites demo app"
}

# Create a new application version linked to the deployment artifacts in the S3 bucket.
# Uses the local release version to create a unique, traceable version label.
resource "aws_elastic_beanstalk_application_version" "whc_app_ebs_version" {
  name        = "whc-app-ebs-version-${local.release}"
  application = aws_elastic_beanstalk_application.whc_app.name
  bucket      = aws_s3_bucket.whc_app_ebs.id
  key         = aws_s3_object.whc_app_deployment.id
}

# Configure the Elastic Beanstalk environment with specific deployment and security settings.
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

  setting {  # not supported in v2
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