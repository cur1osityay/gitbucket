resource "aws_db_instance" "gitbucket_db" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "gitbucket"
  username             = "test"
  password             = "tes345t"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}


resource "aws_codebuild_project" "example" {
  name          = "gitbucket_build"
  description   = "gitbucket codebuild"
  build_timeout = "5"
  # service_role  = aws_iam_role.example.arn

  artifacts {
    encryption_disabled    = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.example.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "cur1osityay/scala-sbt"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "GITBUCKET_DB_URL"
      value = ""
    }
    environment_variable {
      name  = "GITBUCKET_DB_USER"
      value = "SOME_VALUE2"
      # type  = "PARAMETER_STORE"
    }
    environment_variable {
      name  = "GITBUCKET_DB_PASSWORD"
      value = ""
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