#Jenkins iam role

resource "aws_iam_role" "jenkins_role" {

  name = "${var.project_name}-jenkins-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


#attach policy

resource "aws_iam_role_policy_attachment" "jenkins_admin" {

  role = aws_iam_role.jenkins_role.name

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#instance profile

resource "aws_iam_instance_profile" "jenkins_profile" {

  name = "${var.project_name}-jenkins-profile"

  role = aws_iam_role.jenkins_role.name
}