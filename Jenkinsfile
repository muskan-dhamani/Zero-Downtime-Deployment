pipeline {
    agent any

    environment {
        IMAGE_NAME = "zero-downtime-app"
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    stages {

        stage('Info') {
            steps {
                echo "Build Number: ${BUILD_NUMBER}"
                echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build --no-cache -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Deploy with Zero Downtime') {
            steps {
                sh "./deploy.sh ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        success {
            echo "Zero downtime deployment completed successfully :)"
        }
        failure {
            echo "Deployment failed :("
        }
    }
}
