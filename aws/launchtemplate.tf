resource "aws_launch_template" "bastion" {

  # Generate a unique name for the Launch Configuration,
  # so the Auto Scaling Group can be updated without conflict before destroying the previous Launch Configuration.
  # Also see the related lifecycle block below.
  name_prefix = "${var.bastion_name}-"

  count = var.asg_launch_configuration_template == "template" ? 1 : 0

  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name  = aws_iam_instance_profile.bastion.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.bastion_ssh.id]
  }

  user_data = base64gzip(data.template_file.bastion_user_data.rendered)
  key_name         = aws_key_pair.bastion.id

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      encrypted = var.encrypt_root_volume
    }
  }

  lifecycle {
    create_before_destroy = true

    # DO not recreate the Launch Template if a newer AMI becomes available.
    # `terrform taint` the Launch Template resource to force it to be recreated.
    # In the future we may want to also include user-data in this list.
    ignore_changes = [image_id]
  }
}
