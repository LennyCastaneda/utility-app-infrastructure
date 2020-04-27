/******************************************************************************
* IAM
*******************************************************************************/

resource "aws_iam_role" "utility_app" {
  name               = join("-",["${var.name}", "ecs-role"])
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "utility_app" {
  name = join("-",["${var.name}", "ecs-role-policy"])
  role = aws_iam_role.utility_app.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

# AmazonSSMManagedInstanceCore
data "aws_iam_policy" "amazon_ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance" {
  role       = aws_iam_role.utility_app.name
  policy_arn = data.aws_iam_policy.amazon_ssm_managed_instance.arn
}

# AmazonDynamoDBFullAccess
data "aws_iam_policy" "dynamo_db_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "dynamo_db_full_access" {
  role       = aws_iam_role.utility_app.name
  policy_arn = data.aws_iam_policy.dynamo_db_full_access.arn
}

resource "aws_iam_instance_profile" "utility_app" {
  name = join("-",["${var.name}", "instance-profile"])
  role = aws_iam_role.utility_app.name
}