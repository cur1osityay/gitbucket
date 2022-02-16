resource "aws_db_instance" "gitbucket_db" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "gitbucket"
  username             = "test"
  password             = "test"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_codebuild_project" "example" {
  name          = "gitbucket_build"
  description   = "gitbucket codebuild"
  build_timeout = "5"
  service_role  = aws_iam_role.example.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.example.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
    }

    environment_variable {
      name  = "SOME_KEY2"
      value = "SOME_VALUE2"
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