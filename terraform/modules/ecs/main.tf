#################################################
# ECS CLUSTER
#################################################

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

#################################################
# CLOUDWATCH LOG GROUP
#################################################

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ecs-logs"
  }
}

#################################################
# ECS TASK EXECUTION ROLE
#################################################

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role = aws_iam_role.ecs_execution_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#################################################
# ECS TASK DEFINITION
#################################################

resource "aws_ecs_task_definition" "app" {

  family = "${var.project_name}-task"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name = "${var.project_name}-app"

      image = "${var.ecr_repository_url}:latest"

      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "ENVIRONMENT"
          value = "production"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-task"
  }
}

#################################################
# ECS SERVICE
#################################################

resource "aws_ecs_service" "app" {

  name    = "${var.project_name}-service"
  cluster = aws_ecs_cluster.main.id

  task_definition = aws_ecs_task_definition.app.arn

  desired_count = var.desired_count

  launch_type = "FARGATE"



  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {

    subnets = var.subnet_ids

    security_groups = [
      var.ecs_security_group_id
    ]

    assign_public_ip = true
  }

  load_balancer {

    target_group_arn = var.target_group_arn

    container_name = "${var.project_name}-app"

    container_port = var.container_port
  }

  health_check_grace_period_seconds = 60

  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer,
      platform_version
    ]
  }

  tags = {
    Name = "${var.project_name}-service"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy
  ]
}

