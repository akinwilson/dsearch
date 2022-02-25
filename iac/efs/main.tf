resource "aws_efs_file_system" "main" {
  creation_token   = "efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"
  tags = {
    Name        = "${var.name}-efs-${var.environment}"
    Environment = var.environment
  }
}

# An access point applies an operating system user, group,
# and file system path to any file system request made using the access point.
#  The access point's operating system user and group override
#  any identity information provided by the NFS client.
resource "aws_efs_access_point" "main" {
  file_system_id = aws_efs_file_system.main.id
  root_directory {
    # creates directory /efs inside of NFS
    path = "/efs"
    creation_info {
      owner_gid   = 333
      owner_uid   = 10010
      permissions = "0777"
    }
  }
  posix_user {
    gid = 333
    uid = 10010
  }
  tags = {
    Name        = "${var.name}-access-point-${var.environment}"
    Environment = var.environment
  }
}


resource "aws_efs_mount_target" "main" {
  count           = length(var.subnets)
  subnet_id       = element(var.subnets.*.id, count.index)
  file_system_id  = aws_efs_file_system.main.id
  security_groups = var.sg
}


# EFS access point used by lambda and ecs to file system




output "depdency_on_mnt" {
  value = aws_efs_mount_target.main
}

output "access_point" {
  value = aws_efs_access_point.main.arn
}

output "fs" {
  value = aws_efs_file_system.main
}

output "ap" {
  value = aws_efs_access_point.main
}
# output "mnt_arn_lambda" {
#    value = efs_mt.arn
# }

