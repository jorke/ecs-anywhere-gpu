resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = local.tags
}

resource "aws_ecs_service" "external" {
  name            = "${local.name}-external"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 0
  launch_type     = "EXTERNAL"
  # capacity_provider_strategy {
  #   base = 0
  #   capacity_provider = aws_ecs_capacity_provider.external.name
  #   weight = 100
  # }
  tags            = local.tags
}

resource "aws_ecs_service" "ec2" {
  name            = "${local.name}-ec2"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 4
  launch_type     = "EC2"
  # capacity_provider_strategy {
  #   base = 4
  #   capacity_provider = aws_ecs_capacity_provider.ec2.name
  #   weight = 100
  # }
  tags            = local.tags
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "capacityprovider_${aws_autoscaling_group.this.name}"
  # The name cannot be prefixed with "aws", "ecs", or "fargate" whatevs
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = local.target_capacity
    }
  }
}

resource "aws_ecs_capacity_provider" "external" {
  name = "capacityprovider_${aws_autoscaling_group.this.name}"
  # The name cannot be prefixed with "aws", "ecs", or "fargate" whatevs
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = local.target_capacity
    }
  }
}


resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.ec2.name, aws_ecs_capacity_provider.external.name]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ec2.name
  }
}
