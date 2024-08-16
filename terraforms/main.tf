provider "aws" {
  region = "us-east-1" # Altere para sua região
}

# DNS
resource "aws_route53_zone" "main" {
  name = "example.com." # Altere para seu domínio
}

# Load Balancer
resource "aws_elb" "main" {
  name               = "main-load-balancer"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    protocol          = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "app_services" {
  name = "app-services-cluster"
}

# ECS Tasks Definitions
resource "aws_ecs_task_definition" "web_app" {
  family                   = "web-app-task"
  container_definitions    = jsonencode([{
    name      = "web-app"
    image     = "web-app-image" # Altere para a imagem do contêiner
    cpu       = 256
    memory    = 512
    essential = true
  }])
}

# RDS Instance
resource "aws_db_instance" "main_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  instance_class       = "db.t2.micro"
  name                 = "main_db"
  username             = "username"
  password             = "password"
  parameter_group_name = "default.postgres12"
}

resource "aws_db_instance" "read_replica" {
  replicate_source_db = aws_db_instance.main_db.id
  instance_class      = "db.t2.micro"
}

# S3 Bucket
resource "aws_s3_bucket" "product_images" {
  bucket = "product-images-bucket" # Altere para um nome único
}

# SNS Topic
resource "aws_sns_topic" "order_notifications" {
  name = "order-notifications"
}

# SQS Queue
resource "aws_sqs_queue" "order_queue" {
  name = "order-queue"
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name = "/ecs/app-logs"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
}

# IAM Role for ECS
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Service
resource "aws_iam_role" "ecs_service_role" {
  name = "ecs-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_service_policy" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
