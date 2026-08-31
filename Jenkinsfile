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

        CODEDEPLOY_APP   = 'multi-region-cicd-codedeploy-app'
        CODEDEPLOY_GROUP = 'multi-region-cicd-deployment-group'
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

        stage('Register ECS Task Definition') {
            steps {
                script {
                    sh '''
                        sed "s|IMAGE_URI|${ECR_IMAGE}:${IMAGE_TAG}|g" \
                          deploy/taskdef.json \
                          > deploy/taskdef-rendered.json
                    '''

                    env.NEW_TASK_DEF_ARN = sh(
                        script: '''
                            aws ecs register-task-definition \
                              --cli-input-json file://deploy/taskdef-rendered.json \
                              --region ${AWS_REGION} \
                              --query 'taskDefinition.taskDefinitionArn' \
                              --output text
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "New Task Definition: ${env.NEW_TASK_DEF_ARN}"
                }
            }
        }

        stage('Generate AppSpec') {
            steps {
                sh '''
                    cat > deploy/appspec-rendered.yaml <<EOF
version: 0.0

Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "${NEW_TASK_DEF_ARN}"
        LoadBalancerInfo:
          ContainerName: "multi-region-cicd-app"
          ContainerPort: 5000
EOF
                '''

                sh '''
                    echo "Generated AppSpec:"
                    cat deploy/appspec-rendered.yaml
                '''
            }
        }

        stage('Prepare CodeDeploy Revision') {
            steps {
                sh '''
                    python3 - <<'PY'
import json

with open("deploy/appspec-rendered.yaml", "r") as f:
    appspec = f.read()

revision = {
    "revisionType": "AppSpecContent",
    "appSpecContent": {
        "content": appspec
    }
}

with open("deploy/revision.json", "w") as f:
    json.dump(revision, f)
PY
                '''
            }
        }

        stage('Trigger Blue Green Deployment') {
            steps {
                script {
                    env.DEPLOYMENT_ID = sh(
                        script: '''
                            aws deploy create-deployment \
                              --application-name ${CODEDEPLOY_APP} \
                              --deployment-group-name ${CODEDEPLOY_GROUP} \
                              --revision file://deploy/revision.json \
                              --region ${AWS_REGION} \
                              --query deploymentId \
                              --output text
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "CodeDeploy Deployment ID: ${env.DEPLOYMENT_ID}"
                }
            }
        }

        stage('Wait for Deployment') {
            steps {
                sh '''
                    echo "Waiting for CodeDeploy deployment ${DEPLOYMENT_ID}..."

                    aws deploy wait deployment-successful \
                      --deployment-id ${DEPLOYMENT_ID} \
                      --region ${AWS_REGION}

                    echo "Blue/Green deployment completed successfully."
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully.'
            echo "Image deployed: ${ECR_IMAGE}:${IMAGE_TAG}"
            echo "Deployment ID: ${DEPLOYMENT_ID}"
        }

        failure {
            echo 'CI/CD pipeline failed. Check the failed stage above.'
        }

        always {
            sh '''
                rm -rf venv || true
            '''
        }
    }
}