
resource "aws_cloudwatch_log_group" "this" {
  name = "/aws/ecs/${local.name}"
  tags = local.tags
}

resource "aws_ecs_task_definition" "task" {
  tags = local.tags
  container_definitions = jsonencode(
    [
      {
        cpu       = 1024
        essential = true
        image     = "nvcr.io/nvidia/cuda:12.1.1-base-ubuntu22.04"
        memory    = 4096
        name      = "${local.name}-ecs-external"
        command   = ["sh", "-c", "nvidia-smi"]
        # command = ["./deviceQuery"]
        environment = [
          {
            name  = "AWS_REGION"
            value = local.region
          },
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/aws/ecs/${aws_ecs_cluster.this.name}"
            awslogs-region        = local.region
            awslogs-stream-prefix = "external"
          }
        }
        resourceRequirements = [
          {
            "type" : "GPU",
            "value" : "1"
          }
        ]
      },
    ]
  )
  family                   = "ecs-gpu"
  requires_compatibilities = ["EXTERNAL", "EC2"]
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_tasks_role.arn
}
