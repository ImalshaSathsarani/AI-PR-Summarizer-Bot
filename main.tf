variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true  # This hides the value in CLI output
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "gemini_api_key"{
    description = "Gemini API key"
    type = string
    sensitive = true
}


# --- 1. PROVIDER CONFIGURATION ---
provider "aws" {
    region = var.region
}

# --- 2. IAM ROLES (the Bot's Permissions) ---
# This allows ECS to pull images from ECR and send logs to CloudWatch
resource "aws_iam_role" "ecs_task_execution_role" {
    name = "pr-bot-task-execution-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = { Service = "ecs-tasks.amazonaws.com"}
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
    role = aws_iam_role.ecs_task_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- 3. ECR REPOSITORY (The Image Storage) ---
resource "aws_ecr_repository" "bot_repo" {
    name = "pr-summarizer-bot"
}

# --- 4 . ECS CLUSTER & LOGGING ---
resource "aws_ecs_cluster" "bot_cluster"{
    name = "pr-bot-cluster"
}

resource "aws_cloudwatch_log_group" "bot_logs"{
    name = "/aws/ecs/default/pr-summarizer-bot-684a-fa0d"
    retention_in_days = 7
}

# --- 5. ECS TASK DEFINITION (The Blueprint) ---
resource "aws_ecs_task_definition" "bot_task" {
    family = "pr-summarizer-bot-task" 
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = "256" #0.25 vCPU
    memory = "512" #0.5 GB
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

    container_definitions = jsonencode ([{
        name = "bot-container"
        image = "${aws_ecr_repository.bot_repo.repository_url}:latest"
        essential= true
        portMappings = [{
            containerPort = 3000
            hostPort = 3000
        }]

        environment = [
            {name = "PORT", value = "3000" },
            {name = "GEMINI_API_KEY", value = var.gemini_api_key},
            {name= "GITHUB_TOKEN", value= var.github_token}
        ]
        logConfiguration = {
            logDriver = "awslogs"
            options = {
                "awslogs-group" = aws_cloudwatch_log_group.bot_logs.name
                "awslogs-region" = var.region
                "awslogs-stream-prefix" = "ecs"
            }
        }
    }])
}

# ---- 6. ECS SERVICE (The Runner) ----
resource "aws_ecs_service" "bot_service" {
    name = "pr-summarizer-bot-service"
    cluster = aws_ecs_cluster.bot_cluster.id 
    task_definition = aws_ecs_task_definition.bot_task.arn
    launch_type     = "FARGATE"
    desired_count   = 1

    network_configuration {
    subnets          = ["subnet-050384300e7f328ef"] # Find these in your VPC Console
    assign_public_ip = true
    security_groups  = ["sg-0e2b51a05d006af52"] 
  }
}