resource "aws_autoscaling_group" "this" {
  name_prefix           = "${local.name}_"
  max_size              = local.cluster_max
  min_size              = local.cluster_max
  vpc_zone_identifier   = module.vpc.public_subnets
  protect_from_scale_in = true

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = local.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = local.spot_capacity
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
        version            = "$Latest"
      }
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  tag {
    key                 = "ecs-scaling"
    propagate_at_launch = true
    value               = ""
  }
}