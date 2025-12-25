
#CodeBuild Project
resource "aws_codebuild_project" "backend_build" {
  name         = "counter-codebuild"
  description  = "CodeBuild project for counter app"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.ecr_repo.repository_url
    }
    environment_variable {
      name  = "AWS_REGION"
      value = "eu-west-2"
    }
    environment_variable {
      name  = "MY_CODEBUILD_ROLE_ARN"
      value = aws_iam_role.codebuild_role.arn
    }

  }
  source {
    type            = "GITHUB"
    location        = var.github_url
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }
  concurrent_build_limit = 1
  depends_on = [ aws_ecr_repository.ecr_repo ]

}
resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}

resource "aws_codebuild_webhook" "codebuild_webhook" {
  project_name = aws_codebuild_project.backend_build.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/main"
    }
  }
}


resource "aws_iam_role" "codebuild_role" {
  name = "counter-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

# ECR Policy
resource "aws_iam_role_policy_attachment" "codebuild_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  role       = aws_iam_role.codebuild_role.name
}

# CloudWatch Full Access Policy
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.codebuild_role.name
}

# CodeBuild Admin Access Policy to enable codebuild build docker images (requires higher priviligies)
resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  role       = aws_iam_role.codebuild_role.name
}

resource "aws_iam_role_policy" "codebuild_eks_policy" {
  name = "CodeBuildEKSAccess"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster",
          "eks:DescribeClusterVersions",
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:UpdateClusterConfig"
        ],
        Resource = "*"
      }
    ]
  })
}
