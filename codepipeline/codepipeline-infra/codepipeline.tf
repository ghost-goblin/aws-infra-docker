resource "aws_codepipeline" "codepipeline" {
    name = var.codepipeline_name
    role_arn = aws_iam_role.codepipeline_role.arn

    artifact_store {
        type     = "S3"
        location = aws_s3_bucket.codepipeline_bucket.bucket
    }

    stage {
        name = "Source"
        action {
            name = "Source"
            category = "Source"
            owner = "AWS"
            provider = "CodeStarSourceConnection"
            version = "1"
            output_artifacts = ["SourceArtifact"]
            namespace        = "SourceVariables"
            run_order        = 1
            configuration = {
                ConnectionArn    = "${var.codestarconnection_arn}"
                FullRepositoryId = "${var.repo_owner}/${var.repo_name}"
                BranchName       = var.repo_branch
                DetectChanges    = true
                }
        }
    }

    stage {
        name ="Build"
        action {
            name = "Build"
            category = "Build"
            provider = "CodeBuild"
            version = "1"
            owner = "AWS"
            input_artifacts  = ["SourceArtifact"]
            output_artifacts = ["BuildArtifact"]
            namespace        = "BuildVariables"
            run_order        = 1
            configuration = {
                ProjectName = aws_codebuild_project.codebuild_project_build_stage.name
            }
        }
    }

    stage {
        name = "Deploy"
        action {
            name            = "Deploy"
            category        = "Deploy"
            owner           = "AWS"
            provider        = "CodeDeploy"
            version         = "1"
            input_artifacts  = ["BuildArtifact"]
            output_artifacts = []
            namespace        = "DeployVariables"
            run_order        = 1
            configuration = {
                ApplicationName                = aws_codedeploy_app.frontend.name
                DeploymentGroupName            = var.deployment_group_name
            }
        }
    }
}