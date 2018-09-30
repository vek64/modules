
# Declare the data source
data "aws_availability_zones" "all" {}


data "terraform_remote_state" "db" {
	backend = "s3"

	config {
		bucket 	= "${var.db_remote_state_bucket}"
		key 	= "${var.db_remote_state_key}"
		region 	= "us-west-2"
	}
}


data "template_file" "user_data" {
	template = "${file("user-data.sh")}"

	vars {
		server_port = "${var.web_server_port}"
		db_address 	= "${data.terraform_remote_state.db.address}"
		db_port 	= "${data.terraform_remote_state.db.port}"
	}
}



resource "aws_elb" "example" {
    name    =       "elb-${var.cluster_name}"
	availability_zones = ["${data.aws_availability_zones.all.names}"]
    security_groups = ["${aws_security_group.web-elb.id}"]

	listener {
	lb_port		= "${var.web_elb_port}"
	lb_protocol	= "http"
	instance_port	= "${var.web_server_port}"
	instance_protocol = "http"
	}

	health_check {
	healthy_threshold	= 2
	unhealthy_threshold      = 2
	timeout			= 3
	interval		= 30
	target			= "HTTP:${var.web_server_port}/"
	}
}


resource "aws_autoscaling_group" "example" {
	launch_configuration = "${aws_launch_configuration.example.id}"
	availability_zones = ["${data.aws_availability_zones.all.names}"]
	
	load_balancers	= ["${aws_elb.example.name}"]
	health_check_type = "ELB"

	min_size = "${var.min_size}"
	max_size = "${var.max_size}"

        tags    {
			key	= "Name"
			value	= "${var.cluster_name}"
			propagate_at_launch = true
        }
}


resource "aws_launch_configuration" "example" {
	image_id	= "${var.image_id}"
	instance_type	= "${var.instance_type}"
	security_groups = ["${aws_security_group.webinstance.id}"]

	user_data	= "${data.template_file.user_data.rendered}"

	lifecycle {
		create_before_destroy = true
	}

}

resource "aws_security_group" "webinstance" {
    name    =       "web-${var.cluster_name}"
}
resource "aws_security_group_rule" "allow_http_inbound_instance" {
	type 	= "ingress"
	security_group_id	=	"${aws_security_group.webinstance.id}"
	from_port	=	"${var.web_server_port}"
	to_port		=	"${var.web_server_port}"
	protocol	=	"tcp"
	cidr_blocks	=	["0.0.0.0/0"]
}


resource "aws_security_group" "web-elb" {
        name    =       "elb-${var.cluster_name}"
}
resource "aws_security_group_rule" "allow_http_inbound" {
	type 	= "ingress"
	security_group_id	=	"${aws_security_group.web-elb.id}"
	    from_port       =       "${var.web_elb_port}"
        to_port         =       "${var.web_elb_port}"
        protocol        =       "tcp"
        cidr_blocks     =       ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_all_outbound" {
	type 	= "egress"
	security_group_id	=	"${aws_security_group.web-elb.id}"
		from_port       =       0	
        to_port         =       0
        protocol        =       "-1"
        cidr_blocks     =       ["0.0.0.0/0"]
}


resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    count = "${var.enable_autoscaling}"

    scheduled_action_name = "scale-out-during-business-hours"
    min_size            = 2
    max_size            = 10
    desired_capacity    = 10
    recurrence          = "0 9 * * *"

    autoscaling_group_name  = "${module.webserver-cluster.asg_name}"
	    
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    count = "${var.enable_autoscaling}"

    scheduled_action_name = "scale-in-at-night"
    min_size            = 2
    max_size            = 10
    desired_capacity    = 2
    recurrence          = "0 17 * * *"

    autoscaling_group_name  = "${module.webserver-cluster.asg_name}"
    
}
