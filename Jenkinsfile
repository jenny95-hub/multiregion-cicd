pipeline {

    agent any

    environment {
        AWS_ACCOUNT_ID = "772693223288"
        AWS_REGION = "ap-south-1"
        IMAGE_NAME = "cloudops-dashboard"
        ECR_REPOSITORY = "multi-region-cicd-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

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

                export PYTHONPATH=$WORKSPACE

                pytest tests/
                '''
            }
        }

        stage('Trivy Scan') {
    steps {
        sh '''
        trivy image \
        --severity HIGH,CRITICAL \
        --exit-code 1 \
        $IMAGE_NAME:latest
        '''
    }
}


        stage('Docker Build') {
            steps {
                sh '''
                docker build -t $IMAGE_NAME:latest .
                '''
            }
        }


        stage('Push to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login \
                --username AWS \
                --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com


                docker tag $IMAGE_NAME:latest \
                $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG


                docker push \
                $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
                '''
            }
        }

    }
}