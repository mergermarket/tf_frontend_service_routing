resource "aws_alb_target_group" "target_group" {
  name = "${replace(replace("${var.env}-${var.component_name}", "/(.{0,32}).*/", "$1"), "/^-+|-+$/", "")}"

  # port will be set dynamically, but for some reason AWS requires a value
  port                 = "31337"
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    interval            = "${var.health_check_interval}"
    path                = "${var.health_check_path}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
    matcher             = "${var.health_check_matcher}"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags {
    component   = "${var.component_name}"
    environment = "${var.env}"
    service     = "${var.env}-${var.component_name}"
  }
}

resource "aws_alb_listener_rule" "rule" {
  count = "${length(var.path_conditions)}"

  listener_arn = "${var.alb_listener_arn}"
  priority     = "${var.starting_priority + count.index}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.target_group.arn}"
  }

  # Always pass host-based routing condition, with '*.*' being default
  #
  # NOTE: You can have multiple paths but only a single hostname
  condition {
    field  = "host-header"
    values = ["${var.host_condition}"]
  }

  condition {
    field  = "path-pattern"
    values = ["${element(var.path_conditions, count.index)}"]
  }
}
