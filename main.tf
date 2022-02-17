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


resource "aws_codebuild_project" "example" {
  name          = "gitbucket_build"
  description   = "gitbucket codebuild"
  build_timeout = "5"

  artifacts {
    encryption_disabled    = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  # cache {
  #   type     = "S3"
  #   location = 
  # }

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