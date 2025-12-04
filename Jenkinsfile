pipeline {
    agent any

    tools {
        maven 'maven 3.9'
        jdk 'Java 21'
        nodejs 'nodejs-25'
    }

    environment {
        // Docker Hub credentials
        DOCKERHUB = credentials('dockerhub-creds')

        // GitHub repositories
        GITHUB_BACKEND_REPO = 'cheruiyotcollins/investment-platform-backend'
        GITHUB_FRONTEND_REPO = 'cheruiyotcollins/investment-platform-frontend'
        GITHUB_PIPELINE_REPO = 'cheruiyotcollins/investment-platform-pipeline'

        // Docker images
        BACKEND_IMAGE = "kelvincollins86/investment-backend"
        FRONTEND_IMAGE = "kelvincollins86/investment-frontend"

        // Version tags
        VERSION = "${env.BUILD_NUMBER}"
        LATEST_TAG = 'latest'
    }

    parameters {
        choice(
            name: 'BRANCH',
            choices: ['main', 'develop'],
            description: 'Branch to build from'
        )
        choice(
            name: 'TARGET',
            choices: ['backend-only', 'frontend-only', 'full-stack'],
            description: 'What to build'
        )
        booleanParam(
            name: 'RUN_TESTS',
            defaultValue: true,
            description: 'Run tests during build'
        )
        booleanParam(
            name: 'PUSH_TO_REGISTRY',
            defaultValue: false,
            description: 'Push images to Docker Hub'
        )
        booleanParam(
            name: 'DEPLOY_TO_STAGING',
            defaultValue: false,
            description: 'Deploy to staging environment'
        )
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Pipeline Code') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "${params.BRANCH}"]],
                    extensions: [],
                    userRemoteConfigs: [[
                        url: "https://github.com/${GITHUB_PIPELINE_REPO}.git",
                        credentialsId: 'github-credentials'
                    ]]
                ])
            }
        }

        stage('Checkout Application Code') {
            steps {
                script {
                    if (params.TARGET == 'backend-only' || params.TARGET == 'full-stack') {
                        dir('backend') {
                            git(
                                url: "https://github.com/${GITHUB_BACKEND_REPO}.git",
                                branch: "${params.BRANCH}",
                                credentialsId: 'github-credentials'
                            )
                        }
                    }

                    if (params.TARGET == 'frontend-only' || params.TARGET == 'full-stack') {
                        dir('frontend') {
                            git(
                                url: "https://github.com/${GITHUB_FRONTEND_REPO}.git",
                                branch: "${params.BRANCH}",
                                credentialsId: 'github-credentials'
                            )
                        }
                    }
                }
            }
        }

        stage('Run Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                script {
                    if (params.TARGET == 'backend-only' || params.TARGET == 'full-stack') {
                        dir('backend') {
                            sh 'mvn test'
                            junit 'target/surefire-reports/*.xml'
                        }
                    }

                    if (params.TARGET == 'frontend-only' || params.TARGET == 'full-stack') {
                        dir('frontend') {
                            sh 'npm test -- --watchAll=false --passWithNoTests'
                        }
                    }
                }
            }
        }

        stage('Build & Package') {
            steps {
                script {
                    if (params.TARGET == 'backend-only' || params.TARGET == 'full-stack') {
                        dir('backend') {
                            sh 'mvn -B clean package -DskipTests'
                        }
                    }

                    if (params.TARGET == 'frontend-only' || params.TARGET == 'full-stack') {
                        dir('frontend') {
                            sh 'npm run build'
                        }
                    }
                }
            }
        }

        stage('Docker Build & Login') {
            steps {
                script {
                    // Login to Docker Hub
                    sh 'echo $DOCKERHUB_PSW | docker login -u $DOCKERHUB_USR --password-stdin'

                    if (params.TARGET == 'backend-only' || params.TARGET == 'full-stack') {
                        dir('backend') {
                            sh """
                                docker build \
                                  -t ${BACKEND_IMAGE}:${VERSION} \
                                  -t ${BACKEND_IMAGE}:${LATEST_TAG} \
                                  .
                            """
                        }
                    }

                    if (params.TARGET == 'frontend-only' || params.TARGET == 'full-stack') {
                        dir('frontend') {
                            sh """
                                docker build \
                                  -t ${FRONTEND_IMAGE}:${VERSION} \
                                  -t ${FRONTEND_IMAGE}:${LATEST_TAG} \
                                  .
                            """
                        }
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            when {
                expression { params.PUSH_TO_REGISTRY == true }
            }
            steps {
                script {
                    if (params.TARGET == 'backend-only' || params.TARGET == 'full-stack') {
                        sh "docker push ${BACKEND_IMAGE}:${VERSION}"
                        sh "docker push ${BACKEND_IMAGE}:${LATEST_TAG}"
                    }

                    if (params.TARGET == 'frontend-only' || params.TARGET == 'full-stack') {
                        sh "docker push ${FRONTEND_IMAGE}:${VERSION}"
                        sh "docker push ${FRONTEND_IMAGE}:${LATEST_TAG}"
                    }

                    echo "✅ Images pushed to Docker Hub:"
                    echo "Backend: ${BACKEND_IMAGE}:${VERSION}"
                    echo "Frontend: ${FRONTEND_IMAGE}:${VERSION}"
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                expression { params.DEPLOY_TO_STAGING == true }
            }
            steps {
                script {
                    // Load environment variables
                    sh '''
                        if [ -f .env.staging ]; then
                            source .env.staging
                        elif [ -f .env ]; then
                            source .env
                        fi
                    '''

                    // Update docker-compose with current build
                    sh """
                        sed -i 's|\\\${BUILD_TAG}|${VERSION}|g' docker-compose.staging.yml
                        sed -i 's|\\\${DB_NAME}|investment_schema|g' docker-compose.staging.yml
                        sed -i 's|\\\${DB_USER}|collo|g' docker-compose.staging.yml
                    """

                    // Deploy
                    sh 'chmod +x scripts/deploy-staging.sh'
                    sh './scripts/deploy-staging.sh'

                    echo "✅ Deployed to staging with version: ${VERSION}"
                }
            }
        }
    }

    post {
        always {
            // Archive artifacts
            script {
                if (params.TARGET == 'backend-only' || params.TARGET == 'full-stack') {
                    archiveArtifacts artifacts: 'backend/target/*.jar', fingerprint: true
                }
                if (params.TARGET == 'frontend-only' || params.TARGET == 'full-stack') {
                    archiveArtifacts artifacts: 'frontend/build/**', fingerprint: true
                }
            }

            // Clean Docker to save space
            sh 'docker system prune -f --filter "until=24h"'
        }

        success {
            echo "✅ Pipeline #${env.BUILD_NUMBER} completed successfully!"
            echo "Built: ${params.TARGET}"
            echo "Branch: ${params.BRANCH}"
            echo "Version: ${VERSION}"
        }

        failure {
            echo "❌ Pipeline #${env.BUILD_NUMBER} failed!"
        }

        cleanup {
            cleanWs()
        }
    }
}
