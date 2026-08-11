pipeline {
    agent any

    environment {
        AWS_REGION     = 'ap-south-1'
        AWS_ACCOUNT_ID = '772693223288'
        ECR_REPOSITORY = 'multi-region-cicd-app'
        IMAGE_NAME     = 'cloudops-dashboard'
        IMAGE_TAG      = "${BUILD_NUMBER}"

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_IMAGE    = "${ECR_REGISTRY}/${ECR_REPOSITORY}"
    }

    stages {

        stage('Install Dependencies') {
            steps {
                sh '''
                    rm -rf venv

                    python3 -m venv venv

                    ./venv/bin/pip install --upgrade pip

                    ./venv/bin/pip install -r app/requirements.txt
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    export PYTHONPATH=$WORKSPACE
                    ./venv/bin/pytest tests/
                '''
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    trivy fs \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --scanners vuln,secret \
                      .
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build \
                      -t ${IMAGE_NAME}:${IMAGE_TAG} \
                      -t ${IMAGE_NAME}:latest \
                      .
                '''
            }
        }

      stage('Trivy Image Scan') {
    steps {
        sh '''
            echo "Running non-blocking HIGH/CRITICAL vulnerability report..."

            trivy image \
              --severity HIGH,CRITICAL \
              --ignore-unfixed \
              --exit-code 0 \
              --scanners vuln \
              ${IMAGE_NAME}:${IMAGE_TAG}

            echo "Running deployment security gate for CRITICAL vulnerabilities..."

            trivy image \
              --severity CRITICAL \
              --ignore-unfixed \
              --exit-code 1 \
              --scanners vuln \
              ${IMAGE_NAME}:${IMAGE_TAG}
        '''
    }
}
stage('Login to ECR') {
    steps {
        sh '''
            export AWS_PAGER=""

            aws ecr get-login-password \
              --region ${AWS_REGION} | \
            docker login \
              --username AWS \
              --password-stdin \
              ${ECR_REGISTRY}
        '''
    }
}
        stage('Push to ECR') {
            steps {
                sh '''
                    docker tag \
                      ${IMAGE_NAME}:${IMAGE_TAG} \
                      ${ECR_IMAGE}:${IMAGE_TAG}

                    docker tag \
                      ${IMAGE_NAME}:${IMAGE_TAG} \
                      ${ECR_IMAGE}:latest

                    docker push ${ECR_IMAGE}:${IMAGE_TAG}

                    docker push ${ECR_IMAGE}:latest
                '''
            }
        }
    }

    post {
        success {
            echo 'CI pipeline completed successfully.'
            echo "Image pushed: ${ECR_IMAGE}:${IMAGE_TAG}"
        }

        failure {
            echo 'CI pipeline failed. Check the failed stage above.'
        }

        always {
            sh '''
                rm -rf venv || true
            '''
        }
    }
}