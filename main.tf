# Create a new security group
resource "aws_security_group" "allow_all_terra" {
	name        = "allow_all_terra"
	description = "Allow all inbound traffic"

  ingress {
	from_port   = 0
	to_port     = 65535
	protocol    = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }


  tags {
    Name = "allow_all"
  }
}

#Create fisrt alarm

resource "aws_autoscaling_policy" "bat" {
  name                   = "CPU_Usage"
  scaling_adjustment     = 4
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.bar.name}"
}

resource "aws_cloudwatch_metric_alarm" "bat" {
  alarm_name          = "CPU_Usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.bar.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.bat.arn}"]
}

#Create second alarm

resource "aws_autoscaling_policy" "bat2" {
  name                   = "CPU_Usage"
  scaling_adjustment     = 4
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.bar.name}"
}

resource "aws_cloudwatch_metric_alarm" "bat2" {
  alarm_name          = "CPU_Usage2"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "180"
  statistic           = "Average"
  threshold           = "40"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.bar.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.bat.arn}"]
}


# Create a new load balancer
resource "aws_elb" "load_balancer" {
  name               = "load-balancer-terra"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "Load_balancer"
  }
}


# Create a new lauch configuration for the autoscaling group
resource "aws_launch_configuration" "as_conf" {
	name_prefix   	= "launch_configuration"
	image_id      	= "ami-8c1be5f6"
	instance_type 	= "t2.micro"
	key_name        = "poseidonKey"
        security_groups = ["allow_all_terra"]

  lifecycle {
    	create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "bar" {
	name                  	   = "autoscaling_group"
 	launch_configuration 	   = "${aws_launch_configuration.as_conf.name}"
 	availability_zones   	   = ["us-east-1a", "us-east-1b", "us-east-1c"]
 	min_size             	   = 2
 	max_size             	   = 2
	health_check_grace_period  = 300
	health_check_type          = "ELB"
 	desired_capacity           = 2
	load_balancers	     	   = ["load-balancer"]
	


  lifecycle {
	create_before_destroy = true
  }
}

