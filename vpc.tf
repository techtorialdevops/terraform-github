provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count      = 2
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# resource "aws_lb" "this" {
#   name               = "wordpress-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = aws_subnet.public[*].id
# }

# resource "aws_lb_target_group" "this" {
#   name        = "wordpress-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = aws_vpc.main.id
#   target_type = "ip"
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.this.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.this.arn
#   }
# }

# resource "aws_security_group" "alb_sg" {
#   name        = "alb-sg"
#   description = "Allow HTTP inbound traffic"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_ecs_cluster" "wordpress_cluster" {
#   name = "wordpress-cluster"
# }

# resource "aws_iam_role" "ecs_task_execution_role" {
#   name = "ecsTaskExecutionRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# resource "aws_ecs_task_definition" "wordpress" {
#   family                   = "wordpress-task"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256"
#   memory                   = "512"

#   container_definitions = jsonencode([
#     {
#       name      = "wordpress"
#       image     = "wordpress:latest"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#         }
#       ]
#       environment = [
#         {
#           name  = "WORDPRESS_DB_HOST"
#           value = aws_db_instance.default.endpoint
#         },
#         {
#           name  = "WORDPRESS_DB_NAME"
#           value = var.db_name
#         },
#         {
#           name  = "WORDPRESS_DB_USER"
#           value = var.db_user
#         },
#         {
#           name  = "WORDPRESS_DB_PASSWORD"
#           value = var.db_password
#         }
#       ]
#     }
#   ])

#   execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
#   task_role_arn      = aws_iam_role.ecs_task_execution_role.arn
# }

# resource "aws_ecs_service" "wordpress" {
#   name            = "wordpress-service"
#   cluster         = aws_ecs_cluster.wordpress_cluster.id
#   task_definition = aws_ecs_task_definition.wordpress.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"
#   network_configuration {
#     subnets          = aws_subnet.public[*].id
#     security_groups  = [aws_security_group.alb_sg.id]
#     assign_public_ip = true
#   }
#   load_balancer {
#     target_group_arn = aws_lb_target_group.this.arn
#     container_name   = "wordpress"
#     container_port   = 80
#   }
#   depends_on = [aws_lb_listener.http]
# }

# resource "aws_db_instance" "default" {
#   allocated_storage    = var.db_allocated_storage
#   storage_type         = "gp2"
#   engine               = var.db_engine
#   engine_version       = var.db_engine_version
#   instance_class       = var.db_instance_class
#   db_name              = var.db_name
#   username             = var.db_user
#   password             = var.db_password
#   parameter_group_name = "default.mysql5.7"
#   skip_final_snapshot  = true

#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   db_subnet_group_name   = aws_db_subnet_group.default.name
# }

# resource "aws_security_group" "rds_sg" {
#   name        = "rds-sg"
#   description = "Allow MySQL inbound traffic"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_db_subnet_group" "default" {
#   name       = "main"
#   subnet_ids = aws_subnet.private[*].id
# }
