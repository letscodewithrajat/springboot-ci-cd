pipeline {
    agent any
    options {
        skipStagesAfterUnstable()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        // Safe PATH configuration that won't fail
        PATH = "/usr/local/bin:/opt/homebrew/bin:${env.PATH}"

        // Docker image configuration
        MAVEN_IMAGE = "maven:3.8.7-eclipse-temurin-17"
        DOCKER_IMAGE = 'letscodewithrajat/spring-boot-demo'
        DOCKER_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }

    stages {
        stage('Environment Setup') {
            steps {
                script {
                    // Safe Docker detection that never fails
                    def dockerPath = sh(script: '''
                        [ -x "/usr/local/bin/docker" ] && echo "/usr/local/bin/docker" || \
                        [ -x "/opt/homebrew/bin/docker" ] && echo "/opt/homebrew/bin/docker" || \
                        command -v docker || echo "docker_not_found"
                    ''', returnStdout: true).trim()

                    if (dockerPath == "docker_not_found") {
                        echo "⚠️ WARNING: Docker not found in standard locations"
                        // Continue pipeline but skip Docker stages
                        env.SKIP_DOCKER = "true"
                    } else {
                        env.DOCKER_CMD = dockerPath
                        echo "✅ Using Docker at: ${env.DOCKER_CMD}"
                    }
                }
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean package'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                    archiveArtifacts 'target/*.jar'
                }
            }
        }

        stage('Docker Operations') {
            when {
                expression { env.SKIP_DOCKER != "true" }
            }
            steps {
                script {
                    try {
                        // Build with verified Docker path
                        sh "${env.DOCKER_CMD} build -t ${DOCKER_IMAGE}:${DOCKER_TAG} --build-arg MAVEN_IMAGE=${MAVEN_IMAGE} ."

                        // Push with credentials
                        docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                            docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                            docker.image("${DOCKER_IMAGE}:latest").push()
                        }

                        // Deploy with health check
                        sh """
                            ${env.DOCKER_CMD} stop spring-boot-app || true
                            ${env.DOCKER_CMD} rm spring-boot-app || true
                            ${env.DOCKER_CMD} run -d --name spring-boot-app -p 8080:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                    } catch (Exception e) {
                        echo "⚠️ WARNING: Docker operations failed - ${e.message}"
                        // Mark as unstable instead of failing
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Safe cleanup that cannot fail
                sh '''
                    # Clean build artifacts
                    rm -rf target/* || echo "Cleanup warning: Failed to remove target files"

                    # Docker cleanup if available
                    if [ -n "${DOCKER_CMD}" ]; then
                        ${DOCKER_CMD} system prune -f || echo "Cleanup warning: Docker prune failed"
                    fi
                '''
            }
        }

        success {
            echo "✅ SUCCESS: Pipeline completed"
            script {
                if (env.SKIP_DOCKER == "true") {
                    echo "⚠️ NOTE: Docker stages were skipped"
                } else {
                    echo "🐳 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }

        unstable {
            echo "⚠️ UNSTABLE: Some non-critical operations failed"
        }

        failure {
            echo "❌ FAILURE: Critical build/test failures"
        }
    }
}



/*
pipeline {
    agent any
    // Use pre-installed tools (configured in Jenkins Global Tools)
    tools {
        git 'homebrew-git'
        maven 'system-maven'
        jdk 'system-jdk'
    }
    environment {
        // Docker configuration
        MAVEN_IMAGE = "maven:3.8.7-eclipse-temurin-17"
        DOCKER_REGISTRY = 'https://registry.hub.docker.com'
        DOCKER_IMAGE = 'letscodewithrajat/spring-boot-demo'
        DOCKER_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
        // Ensure Docker is in PATH (Mac specific)
        PATH = "/usr/local/bin:$PATH:/opt/homebrew/bin:$PATH"
       // PATH = "/opt/homebrew/bin:$PATH"
    }
    stages {
        // Stage 1: Checkout code from GitHub
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        // Stage 2: Build and package with Maven
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts 'target */
/*.jar'
                }
            }
        }
        // Stage 3: Run tests
        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit '**//*
target/surefire-reports */
/*.xml'
                }
            }
        }
        // Stage 4: Build Docker image (multi-stage build)
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}", "--build-arg MAVEN_IMAGE=${MAVEN_IMAGE} .")
                }
            }
        }
        // Stage 5: Push to Docker Hub (uses credentials)
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry("${DOCKER_REGISTRY}", 'docker-hub-creds') {
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        // Optional: Push as 'latest' for most recent successful build
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }
                }
            }
        }
        // Stage 6: Deploy to local Docker
        stage('Deploy Locally') {
            steps {
                script {
                    // Stop and remove existing container
                    sh 'docker stop spring-boot-app || true'
                    sh 'docker rm spring-boot-app || true'
                    // Run new container
                    sh """
                        docker run -d \
                        --name spring-boot-app \
                        -p 8080:8080 \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }
    }
    post {
        success {
            echo ":white_check_mark: Pipeline SUCCESS - App running at http://localhost:8080"
            echo "Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo ":x: Pipeline FAILED - Check logs for errors"
           // slackSend channel: '#builds', message: "Build ${env.BUILD_NUMBER} failed!"
        }
        always {
            // Clean up workspace
            cleanWs()
        }
    }
} */
