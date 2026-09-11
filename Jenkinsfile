pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '772693223288'

        PRIMARY_REGION   = 'ap-south-1'
        SECONDARY_REGION = 'ap-southeast-1'

        ECR_REPOSITORY = 'multi-region-cicd-app'
        IMAGE_NAME     = 'cloudops-dashboard'
        IMAGE_TAG      = "${BUILD_NUMBER}"

        PRIMARY_ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${PRIMARY_REGION}.amazonaws.com"
        SECONDARY_ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${SECONDARY_REGION}.amazonaws.com"

        PRIMARY_ECR_IMAGE   = "${PRIMARY_ECR_REGISTRY}/${ECR_REPOSITORY}"
        SECONDARY_ECR_IMAGE = "${SECONDARY_ECR_REGISTRY}/${ECR_REPOSITORY}"

        PRIMARY_CODEDEPLOY_APP   = 'multi-region-cicd-codedeploy-app'
        PRIMARY_CODEDEPLOY_GROUP = 'multi-region-cicd-deployment-group'

        SECONDARY_CODEDEPLOY_APP   = 'multi-region-cicd-secondary-codedeploy-app'
        SECONDARY_CODEDEPLOY_GROUP = 'multi-region-cicd-secondary-deployment-group'
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
                    echo "Running non-blocking HIGH/CRITICAL report..."

                    trivy image \
                      --severity HIGH,CRITICAL \
                      --ignore-unfixed \
                      --exit-code 0 \
                      --scanners vuln \
                      ${IMAGE_NAME}:${IMAGE_TAG}

                    echo "Running blocking CRITICAL vulnerability gate..."

                    trivy image \
                      --severity CRITICAL \
                      --ignore-unfixed \
                      --exit-code 1 \
                      --scanners vuln \
                      ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Login to Primary ECR') {
            steps {
                sh '''
                    export AWS_PAGER=""

                    aws ecr get-login-password \
                      --region ${PRIMARY_REGION} | \
                    docker login \
                      --username AWS \
                      --password-stdin \
                      ${PRIMARY_ECR_REGISTRY}
                '''
            }
        }

        stage('Push Image to Primary ECR') {
            steps {
                sh '''
                    docker tag \
                      ${IMAGE_NAME}:${IMAGE_TAG} \
                      ${PRIMARY_ECR_IMAGE}:${IMAGE_TAG}

                    docker tag \
                      ${IMAGE_NAME}:${IMAGE_TAG} \
                      ${PRIMARY_ECR_IMAGE}:latest

                    docker push ${PRIMARY_ECR_IMAGE}:${IMAGE_TAG}
                    docker push ${PRIMARY_ECR_IMAGE}:latest
                '''
            }
        }

        stage('Login to Secondary ECR') {
            steps {
                sh '''
                    aws ecr get-login-password \
                      --region ${SECONDARY_REGION} | \
                    docker login \
                      --username AWS \
                      --password-stdin \
                      ${SECONDARY_ECR_REGISTRY}
                '''
            }
        }

        stage('Promote Image to Secondary ECR') {
            steps {
                sh '''
                    docker tag \
                      ${IMAGE_NAME}:${IMAGE_TAG} \
                      ${SECONDARY_ECR_IMAGE}:${IMAGE_TAG}

                    docker tag \
                      ${IMAGE_NAME}:${IMAGE_TAG} \
                      ${SECONDARY_ECR_IMAGE}:latest

                    docker push ${SECONDARY_ECR_IMAGE}:${IMAGE_TAG}
                    docker push ${SECONDARY_ECR_IMAGE}:latest
                '''
            }
        }

        stage('Register Primary ECS Task Definition') {
            steps {
                script {
                    sh '''
                        sed "s|IMAGE_URI|${PRIMARY_ECR_IMAGE}:${IMAGE_TAG}|g" \
                          deploy/taskdef.json \
                          > deploy/taskdef-primary-rendered.json
                    '''

                    env.PRIMARY_TASK_DEF_ARN = sh(
                        script: '''
                            aws ecs register-task-definition \
                              --cli-input-json file://deploy/taskdef-primary-rendered.json \
                              --region ${PRIMARY_REGION} \
                              --query 'taskDefinition.taskDefinitionArn' \
                              --output text
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Primary Task Definition: ${env.PRIMARY_TASK_DEF_ARN}"
                }
            }
        }

        stage('Generate Primary AppSpec') {
            steps {
                sh '''
                    cat > deploy/appspec-primary-rendered.yaml <<EOF
version: 0.0

Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "${PRIMARY_TASK_DEF_ARN}"
        LoadBalancerInfo:
          ContainerName: "multi-region-cicd-app"
          ContainerPort: 5000
EOF
                '''
            }
        }

        stage('Prepare Primary CodeDeploy Revision') {
            steps {
                sh '''
                    python3 - <<'PY'
import json

with open("deploy/appspec-primary-rendered.yaml", "r") as f:
    appspec = f.read()

revision = {
    "revisionType": "AppSpecContent",
    "appSpecContent": {
        "content": appspec
    }
}

with open("deploy/revision-primary.json", "w") as f:
    json.dump(revision, f)
PY
                '''
            }
        }

        stage('Deploy Primary Region') {
            steps {
                script {
                    env.PRIMARY_DEPLOYMENT_ID = sh(
                        script: '''
                            aws deploy create-deployment \
                              --application-name ${PRIMARY_CODEDEPLOY_APP} \
                              --deployment-group-name ${PRIMARY_CODEDEPLOY_GROUP} \
                              --revision file://deploy/revision-primary.json \
                              --region ${PRIMARY_REGION} \
                              --query deploymentId \
                              --output text
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Primary Deployment ID: ${env.PRIMARY_DEPLOYMENT_ID}"
                }
            }
        }

        stage('Wait for Primary Deployment') {
            steps {
                sh '''
                    aws deploy wait deployment-successful \
                      --deployment-id ${PRIMARY_DEPLOYMENT_ID} \
                      --region ${PRIMARY_REGION}

                    echo "Primary Mumbai deployment completed successfully."
                '''
            }
        }

        stage('Register Secondary ECS Task Definition') {
            steps {
                script {
                    sh '''
                        sed "s|IMAGE_URI|${SECONDARY_ECR_IMAGE}:${IMAGE_TAG}|g" \
                          deploy/taskdef-secondary.json \
                          > deploy/taskdef-secondary-rendered.json
                    '''

                    env.SECONDARY_TASK_DEF_ARN = sh(
                        script: '''
                            aws ecs register-task-definition \
                              --cli-input-json file://deploy/taskdef-secondary-rendered.json \
                              --region ${SECONDARY_REGION} \
                              --query 'taskDefinition.taskDefinitionArn' \
                              --output text
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Secondary Task Definition: ${env.SECONDARY_TASK_DEF_ARN}"
                }
            }
        }

        stage('Generate Secondary AppSpec') {
            steps {
                sh '''
                    cat > deploy/appspec-secondary-rendered.yaml <<EOF
version: 0.0

Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "${SECONDARY_TASK_DEF_ARN}"
        LoadBalancerInfo:
          ContainerName: "multi-region-cicd-secondary-app"
          ContainerPort: 5000
EOF
                '''
            }
        }

        stage('Prepare Secondary CodeDeploy Revision') {
            steps {
                sh '''
                    python3 - <<'PY'
import json

with open("deploy/appspec-secondary-rendered.yaml", "r") as f:
    appspec = f.read()

revision = {
    "revisionType": "AppSpecContent",
    "appSpecContent": {
        "content": appspec
    }
}

with open("deploy/revision-secondary.json", "w") as f:
    json.dump(revision, f)
PY
                '''
            }
        }

        stage('Deploy Secondary Region') {
            steps {
                script {
                    env.SECONDARY_DEPLOYMENT_ID = sh(
                        script: '''
                            aws deploy create-deployment \
                              --application-name ${SECONDARY_CODEDEPLOY_APP} \
                              --deployment-group-name ${SECONDARY_CODEDEPLOY_GROUP} \
                              --revision file://deploy/revision-secondary.json \
                              --region ${SECONDARY_REGION} \
                              --query deploymentId \
                              --output text
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Secondary Deployment ID: ${env.SECONDARY_DEPLOYMENT_ID}"
                }
            }
        }

        stage('Wait for Secondary Deployment') {
            steps {
                sh '''
                    aws deploy wait deployment-successful \
                      --deployment-id ${SECONDARY_DEPLOYMENT_ID} \
                      --region ${SECONDARY_REGION}

                    echo "Secondary Singapore deployment completed successfully."
                '''
            }
        }
    }

    post {
        success {
            echo 'Multi-region CI/CD pipeline completed successfully.'
            echo "Primary image: ${PRIMARY_ECR_IMAGE}:${IMAGE_TAG}"
            echo "Secondary image: ${SECONDARY_ECR_IMAGE}:${IMAGE_TAG}"
            echo "Primary deployment: ${PRIMARY_DEPLOYMENT_ID}"
            echo "Secondary deployment: ${SECONDARY_DEPLOYMENT_ID}"
        }

        failure {
            echo 'Multi-region CI/CD pipeline failed. Check the failed stage.'
        }

        always {
            sh '''
                rm -rf venv || true
            '''
        }
    }
}