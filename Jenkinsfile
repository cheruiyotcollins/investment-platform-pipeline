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

        // ✅ UPDATED: Correct GitHub repositories
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
            choices: ['main', 'master'],  // ✅ ADDED 'master' option
            description: 'Branch to build from'
        )
        // ... rest of parameters
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
                    branches: [[name: "* */${params.BRANCH}"]],  // ✅ CHANGED: Wildcard branch
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
                                credentialsId: 'github-credentials',
                                changelog: false,  // ✅ ADDED
                                poll: false        // ✅ ADDED
                            )
                        }
                    }

                    if (params.TARGET == 'frontend-only' || params.TARGET == 'full-stack') {
                        dir('frontend') {
                            git(
                                url: "https://github.com/${GITHUB_FRONTEND_REPO}.git",
                                branch: "${params.BRANCH}",
                                credentialsId: 'github-credentials',
                                changelog: false,  // ✅ ADDED
                                poll: false        // ✅ ADDED
                            )
                        }
                    }
                }
            }
        }
        // ... rest of stages
    }
}
