variable web_server_port {
	description = "The port server will use to listen for HTTP"
	default	= 8080
}


variable web_elb_port {
        description = "The port server will use to listen for HTTP"
        default = 80
}


variable "cluster_name" {
	description = "Name for all Cluster resources"
}


variable "db_remote_state_bucket" {
	description = "Name for S3 state bucket"
}

variable "db_remote_state_key" {
	description = "Name for remote state path key"
}

variable "instance_type" {
	description = "Instance type it is, eg micro or nano"
}

variable "ami" {
  description = "The AMI to run in the cluster"
  default     = "ami-0e32ec5bc225539f5"
}

variable "min_size" {
	description = "Min size for ASG group"
}

variable "max_size" {
	description = "Max size for ASG group"
}

variable "enable_autoscaling" {
	description = "if set to TRUE, enable auto scaling"
	default     = false
}


variable "server_text" {
  description = "The text the web server should return"
  default     = "Hello by DEFAULT, World from VEK"
}