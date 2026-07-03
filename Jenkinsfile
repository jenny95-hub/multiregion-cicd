pipeline {
    agent any

    environment {
        IMAGE_NAME = "cloudops-dashboard"
        AWS_REGION = "ap-south-1"
        ECR_REPO = "772693223288.dkr.ecr.ap-south-1.amazonaws.com/multi-region-cicd-app"
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
        python3 -m venv venv

        . venv/bin/activate

        pip install --upgrade pip

        pip install -r app/requirements.txt
        '''
    }
}
       stage('Run Tests') {
    steps {
        sh '''
        . venv/bin/activate

        pytest tests/
        '''
    }
}

        stage('Docker Build') {
            steps {
                sh 'docker build -t $IMAGE_NAME:latest .'
            }
        }

     

    }
}
