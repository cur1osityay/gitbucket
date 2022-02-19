resource "aws_db_instance" "gitbucket_db" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = var.db_name
  username             = var.db_user
  password             = var.db_pass
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  } 

  stage {
      name = "Source"

      action {
        name             = "Source"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["source_output"]

        configuration = {
          ConnectionArn    = aws_codestarconnections_connection.example.arn
          FullRepositoryId = "my-organization/example"
          BranchName       = "main"
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
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "test"
      }
    }
  }
stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CloudFormation"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ActionMode     = "REPLACE_ON_FAILURE"
        Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
        OutputFileName = "CreateStackOutput.json"
        StackName      = "MyStack"
        TemplatePath   = "build_output::sam-templated.yaml"
          } 
        } 
      }
}

#GITBUCKET_BASE_URL=http://

resource "aws_codebuild_project" "example" {
  name          = "gitbucket_build"
  description   = "gitbucket codebuild"
  build_timeout = "5"

  artifacts {
    encryption_disabled    = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "cur1osityay/scala-sbt"
    type                        = "LINUX_CONTAINER"

    environment_variable {
      name  = "GITBUCKET_BASE_URL"
      value = aws_db_instance.gitbucket_db.name
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "GITBUCKET_DB_USER"
      value = var.db_user
      type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "GITBUCKET_DB_PASSWORD"
      value = var.db_pass
      type  = "PARAMETER_STORE"
    }
  }
source {
    type            = "GITHUB"
    location        = "https://github.com/cur1osityay/gitbucket.git"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }
source_version = "master"
}

resource "aws_elastic_beanstalk_application" "eb-app" {
  name        = "eb-app"
  description = "application gb"
}

resource "aws_elastic_beanstalk_configuration_environment" "eb-env" {
  name                = "eb-env-config"
  application         = aws_elastic_beanstalk_application.eb-app.name
  solution_stack_name = "64bit Amazon Linux 2 v4.2.11 running Tomcat 8.5 Corretto 11"
  setting {
    namespace = "aws:ec2:instances"
    name = "InstanceTypes"
    value = "t2.micro"
  } 
}


