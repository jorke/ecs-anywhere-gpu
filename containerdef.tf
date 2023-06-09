
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${local.name}"
  tags = local.tags
}

resource "aws_ecs_task_definition" "task" {
  tags = local.tags
  container_definitions = jsonencode(
    [
      {
        cpu       = 128
        essential = true
        image     = "nvcr.io/nvidia/cuda:12.1.1-base-ubuntu22.04"
        memory    = 256
        name      = "${local.name}-ecs-external"
        command   = [ "sh", "-c", "nvidia-smi" ]
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
                "type": "GPU",
                "value": "1"
            }
        ]
      },
    ]
  )

#   volume {
#     name      = "share"
#     host_path = "/data"
#   }

  family                   = "ecs-gpu"
  requires_compatibilities = ["EXTERNAL"]
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_tasks_role.arn
}


# "resourceRequirements": [{
#         "type":"GPU",
#         "value": "1"
#       }],

# image     = aws_ecr_repository.ecs.repository_url
# mountPoints = [
#           {
#             containerPath = "/data"
#             sourceVolume  = "share"
#           },
#         ]

#         logConfiguration = {
#           logDriver = "awslogs"
#           options = {
#             awslogs-group         = "ecs-external-${aws_ecs_cluster.ecs-cluster.name}"
#             awslogs-region        = var.aws_region
#             awslogs-stream-prefix = "external"
#           }
#         }
