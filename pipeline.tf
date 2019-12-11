provider "aws" {
  region = "us-east-2"
}


#IAM Roles Create for CodeBuild and CodePipeline
#CodeBuild Role
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#CodeBuild Policy
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild_policy"
  role = "${aws_iam_role.codebuild_role.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "s3:*",
                "logs:*",
                "ecr:*",
                "s3:List*",
                "codebuild:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#CodePipeline Role
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#CodePipeline Policy
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::*:role/service-role/cwe-role-*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "events.amazonaws.com"
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "codepipeline.amazonaws.com"
                }
            }
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "codestar-notifications:CreateNotificationRule",
                "codestar-notifications:DescribeNotificationRule",
                "codestar-notifications:UpdateNotificationRule",
                "codestar-notifications:Subscribe",
                "codestar-notifications:Unsubscribe",
                "codestar-notifications:DeleteNotificationRule"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "codestar-notifications:NotificationsForResource": "arn:aws:codepipeline:*"
                }
            }
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "codedeploy:BatchGetDeploymentGroups",
                "opsworks:DescribeStacks",
                "codestar-notifications:ListNotificationRules",
                "lambda:GetFunctionConfiguration",
                "codedeploy:ListApplications",
                "codebuild:*",
                "codestar-notifications:ListEventTypes",
                "devicefarm:ListDevicePools",
                "devicefarm:GetDevicePool",
                "elasticbeanstalk:DescribeEnvironments",
                "devicefarm:GetProject",
                "events:ListRules",
                "codedeploy:BatchGetApplications",
                "events:ListTargetsByRule",
                "devicefarm:ListProjects",
                "codedeploy:GetDeploymentGroup",
                "iam:GetRole",
                "events:DescribeRule",
                "lambda:ListFunctions",
                "codecommit:GetRepositoryTriggers",
                "cloudtrail:DescribeTrails",
                "cloudformation:DescribeStacks",
                "codedeploy:ListDeploymentGroups",
                "ec2:DescribeSubnets",
                "opsworks:DescribeApps",
                "cloudtrail:StartLogging",
                "sns:ListTopics",
                "cloudtrail:GetEventSelectors",
                "codecommit:GetReferences",
                "ecr:ListImages",
                "codecommit:ListRepositories",
                "codestar-notifications:ListTagsForResource",
                "ecs:ListServices",
                "opsworks:DescribeLayers",
                "elasticbeanstalk:DescribeApplications",
                "ecr:DescribeRepositories",
                "codedeploy:GetApplication",
                "ecs:ListClusters",
                "codecommit:PutRepositoryTriggers",
                "codecommit:ListBranches",
                "cloudtrail:PutEventSelectors",
                "s3:*",
                "iam:ListRoles",
                "ec2:DescribeSecurityGroups",
                "codestar-notifications:ListTargets",
                "ec2:DescribeVpcs",
                "cloudtrail:CreateTrail",
                "codecommit:GetBranch",
                "codepipeline:*",
                "cloudformation:ListChangeSets"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor4",
            "Effect": "Allow",
            "Action": [
                "events:PutTargets",
                "events:DeleteRule",
                "s3:GetObject",
                "events:PutRule",
                "sns:CreateTopic",
                "s3:PutBucketPolicy",
                "s3:CreateBucket",
                "events:RemoveTargets",
                "sns:SetTopicAttributes",
                "events:DisableRule"
            ],
            "Resource": [
                "arn:aws:events:*:*:rule/codepipeline-*",
                "arn:aws:s3::*:codepipeline-*",
                "arn:aws:sns:*:*:codestar-notifications*"
            ]
        }
    ]
}
EOF
}


#CodeBuild Steps
data "template_file" "buildspec" {
  template = "${file("./buildspec.yml")}"

}

  resource "aws_s3_bucket" "source" {
  bucket = "mycustompipelinebucket"
  acl    = "private"
}


resource "aws_codebuild_project" "openjobs_build" {
  name          = "openjobs-codebuild"
  build_timeout = "10"
  service_role  = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    // https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    image           = "aws/codebuild/docker:1.12.1"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${data.template_file.buildspec.rendered}"
  }
}


#CodePipeline Step
resource "aws_codepipeline" "pipeline" {
  name     = "openjobs-pipeline"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"


  artifact_store {
    location = "${aws_s3_bucket.source.bucket}"
    type     = "S3"
}


  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration {
        Owner      = "kubragogebakan"
        Repo       = "hello-world"
        Branch     = "master"
        OAuthToken = "2394206568e21abb5e8581328c078fcf7ca30b81" #GithubTokenCredential
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["imagedefinitions"]

      configuration {
        ProjectName = "openjobs-codebuild"
      }
    }
  }

  stage {
    name = "Production"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefinitions"]
      version         = "1"

      configuration {
        ClusterName = "${var.ecs_cluster_name}"
        ServiceName = "${var.ecs_service_name}"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
