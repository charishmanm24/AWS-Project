# ==============================================================================
# 1. SECURITY TIER (Firewalls & Zero Trust Network Isolation)
# ==============================================================================

# Public Web Facing Load Balancer Security Group
resource "aws_security_group" "load_balancer_security_edge" {
  name        = "${var.environment}-ecs-alb-sg"
  description = "Controls public inbound access rules into the application load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permits public web requests
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-ecs-alb-security-group" }
}

# Private Serverless Container Tasks Security Group
resource "aws_security_group" "container_workload_isolation" {
  name        = "${var.environment}-ecs-tasks-sg"
  description = "Isolates serverless container tasks from external direct network scans"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_security_edge.id] # Least Privilege: ONLY traffic from ALB allowed!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-ecs-tasks-security-group" }
}

# ==============================================================================
# 2. ROUTING TIER (High Availability Application Load Balancer)
# ==============================================================================

resource "aws_lb" "application_routing_hub" {
  name               = "${var.environment}-app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_edge.id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.environment}-main-application-alb" }
}

resource "aws_lb_target_group" "container_target_pool" {
  name        = "${var.environment}-container-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Crucial: Fargate requires target allocation mapped by virtual IP address

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http_ingress_router" {
  load_balancer_arn = aws_lb.application_routing_hub.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.container_target_pool.arn
  }
}

# ==============================================================================
# 3. ECS COMPUTE LAYER (Orchestrator Cluster & Serverless Tasks)
# ==============================================================================

# Core Orchestration Cluster
resource "aws_ecs_cluster" "production_container_grid" {
  name = "${var.environment}-ecs-orchestration-cluster"
  
  tags = { Name = "${var.environment}-ecs-cluster" }
}

# IAM Execution Profile Role (Gives ECS permission to pull down Docker application images)
resource "aws_iam_role" "container_execution_profile" {
  name = "${var.environment}-ecs-execution-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "attach_standard_ecs_policy" {
  role       = aws_iam_role.container_execution_profile.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Centralized Monitoring for Serverless Logs
resource "aws_cloudwatch_log_group" "container_monitoring_logs" {
  name              = "/ecs/${var.environment}-web-application"
  retention_in_days = 7 # Automatically purges old log traces to optimize cloud costs

  tags = {
    Name        = "${var.environment}-ecs-log-group"
    Environment = var.environment
  }
}

# Task Definition with Integrated Logging Agent
resource "aws_ecs_task_definition" "web_application_blueprint" {
  family                   = "${var.environment}-web-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.container_execution_profile.arn

  container_definitions = jsonencode([{
    name      = "web-service-cell"
    image     = "nginx:alpine"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.container_monitoring_logs.name
        "awslogs-region"        = "ap-south-1"
        "awslogs-stream-prefix" = "fargate-worker"
      }
    }
  }])
}

# Grants Fargate the ability to stream runtime logs directly out to the CloudWatch API
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_logging_policy" {
  role       = aws_iam_role.container_execution_profile.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}


# Continuous Active Service Engine Manager
resource "aws_ecs_service" "orchestrated_runtime_service" {
  name            = "${var.environment}-core-microservice"
  cluster         = aws_ecs_cluster.production_container_grid.id
  task_definition = aws_ecs_task_definition.web_application_blueprint.arn
  desired_count   = 2 # High Availability: Forces 2 identical container copies to always run in parallel
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids # Safely isolated deep inside our private network subnets
    security_groups  = [aws_security_group.container_workload_isolation.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.container_target_pool.arn
    container_name   = "web-service-cell"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http_ingress_router]
}

# ==============================================================================
# 4. SECURITY TIER (AWS WAFv2 Layer 7 Protection Shield)
# ==============================================================================

# WAFv2 Web Access Control List (Web ACL)
resource "aws_wafv2_web_acl" "alb_security_shield" {
  name        = "${var.environment}-alb-waf-shield"
  description = "Layer 7 firewall blocking common vulnerabilities and brute-force web vector sets"
  scope       = "REGIONAL" 

  default_action {
    allow {} 
  }

  # Rule 1: AWS Common Vulnerabilities Managed Rule Set (Protects against SQLi, XSS, local file inclusion)
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-waf-common-rules-metric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: IP Rate Limiting Shield (Blocks brute-force vectors and Layer 7 DDoS flooding)
  rule {
    name     = "RateLimitShield"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500 # Max requests permitted per rolling 5-minute window per singular source IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-waf-rate-limit-metric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-waf-global-acl-metric"
    sampled_requests_enabled   = true
  }
}

# Bind the WAFv2 Web ACL directly to your Application Load Balancer
resource "aws_wafv2_web_acl_association" "waf_alb_binding" {
  resource_arn = aws_lb.application_routing_hub.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_security_shield.arn
}
