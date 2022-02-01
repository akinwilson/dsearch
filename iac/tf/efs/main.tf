resource "aws_efs_file_system" "efs" {
   creation_token = "efs"
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"

   tags = {
       Name        = "${var.name}-efs-${var.environment}"
       Environment = var.environment
    }
}


resource "aws_efs_mount_target" "efs_mt" {
   count = length(var.subnets)
   # subnets = var.subnets.value
   subnet_id = "${element(var.subnets.*.id, count.index)}"
   file_system_id  = aws_efs_file_system.efs.id
   security_groups = [var.sg]
 }


# EFS access point used by lambda file system
resource "aws_efs_access_point" "access_point_for_lambda" {
  file_system_id = aws_efs_file_system.efs.id
  root_directory {
    path = "/lambda"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "777"
    }
  }
  posix_user {
    gid = 1000
    uid = 1000
  }
}

output = "depdency_on_mnt" {
  value = aws_efs_mount_target.efs 
}
  
output "access_point_lambda_arn" {
  value = aws_efs_access_point.access_point_for_lambda.arn
}
# output "mnt_arn_lambda" {
#    value = efs_mt.arn
# }

