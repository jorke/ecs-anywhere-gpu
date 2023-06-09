data "cloudinit_config" "ecs" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<EOF
#!/bin/bash
echo ECS_CLUSTER="${local.name}" >> /etc/ecs/ecs.config
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
echo ECS_ENABLE_SPOT_INSTANCE_DRAINING=${tostring(local.spot)} >> /etc/ecs/ecs.config

EOF
  }
}

resource "aws_iam_instance_profile" "ecs_node" {
  name = "${local.name}_Ec2InstanceProfile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_launch_template" "this" {
  name_prefix            = "${local.name}_"
  image_id               = jsondecode(data.aws_ssm_parameter.gpu_ami.value).image_id
  instance_type          = "g4dn.12xlarge"
  vpc_security_group_ids = [aws_security_group.this.id]
  user_data              = data.cloudinit_config.ecs.rendered
  tags                   = local.tags
  update_default_version = true
  key_name               = local.key_pair

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 100
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }
}