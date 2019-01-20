resource "aws_batch_job_definition" "container" {
  name                  = "${var.env}-${var.name}"
  type                  = "${var.batch_type}"
  container_properties  = "${var.container_properties}"
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.env}-${var.name}-ecs_instance_role"
  assume_role_policy = "${file("${path.module}/ecs_instance_role.json")}"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "ecs_instance_role"
  role = "${aws_iam_role.ecs_instance_role.name}"
}

resource "aws_iam_role" "aws_batch_service_role" {
  name = "${var.env}-${var.name}-aws_batch_service_role"

  assume_role_policy = "${file("${path.module}/batch_service_role.json")}"
  }

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = "${aws_iam_role.aws_batch_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_security_group" "sample" {
  name = "aws_batch_compute_environment_security_group"
}

resource "aws_vpc" "sample" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "sample" {
  vpc_id     = "${aws_vpc.sample.id}"
  cidr_block = "10.1.1.0/24"
}

resource "aws_batch_compute_environment" "sample" {
  compute_environment_name = "${var.env}-${var.name}"

  compute_resources {
    instance_role = "${aws_iam_instance_profile.ecs_instance_role.arn}"

    instance_type = [ "${var.instance_types}"]

    max_vcpus = "${var.max_cpus}"
    min_vcpus = "${var.min_cpus}"

    security_group_ids = ["${aws_security_group.sample.id}",]

    subnets = [ "${aws_subnet.sample.id}",]

    type = "EC2"
  }

  service_role = "${aws_iam_role.aws_batch_service_role.arn}"
  type         = "MANAGED"
  depends_on   = ["aws_iam_role_policy_attachment.aws_batch_service_role"]
}