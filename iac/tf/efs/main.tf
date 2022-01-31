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


resource "aws_efs_mount_target" "efs-mt" {
   # count = length(var.private_subnets)
   # file_system_id  = aws_efs_file_system.efs.id
   # subnet_id     = element(aws_subnet.public.*.id, count.index)
   # depends_on    = [aws_internet_gateway.main]
   # security_groups = [aws_security_group.efs.id]
   count = length(var.subnets)
   # subnets = var.subnets.value
   subnet_id = "${element(var.subnets.*.id, count.index)}"
   file_system_id  = aws_efs_file_system.efs.id
   security_groups = [var.sg]
 }


