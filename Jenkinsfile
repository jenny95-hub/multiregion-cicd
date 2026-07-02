pipeline {
    agent any

    environment {
        IMAGE_NAME = "cloudops-dashboard"
        AWS_REGION = "ap-south-1"
        ECR_REPO = "<your-account-id>.dkr.ecr.ap-south-1.amazonaws.com/cloudops-dashboard"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                python3 -m pip install --upgrade pip
                pip install -r app/requirements.txt
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh 'pytest tests/'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t $IMAGE_NAME:latest .'
            }
        }

        stage('Login to ECR') {
    steps {
        sh '''
        aws ecr get-login-password --region ap-south-1 | \
        docker login --username AWS --password-stdin $ECR_REPO
        '''
    }
}
stage('Push Image to ECR') {
    steps {
        sh '''
        docker tag $IMAGE_NAME:latest $ECR_REPO:latest
        docker push $ECR_REPO:latest
        '''
    }
}

    }
}