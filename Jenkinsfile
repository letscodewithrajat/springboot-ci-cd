pipeline {
    agent any
    options {
        skipStagesAfterUnstable()
        timeout(time: 30, unit: 'MINUTES')
        retry(1) // Single retry for whole pipeline
    }

    environment {
        // Universal PATH configuration (works for both Intel and Apple Silicon)
        PATH = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

        // Docker configuration
        DOCKER_CMD = sh(script: 'command -v docker || echo /usr/local/bin/docker', returnStdout: true).trim()
        MAVEN_IMAGE = "maven:3.8.7-eclipse-temurin-17"
        DOCKER_IMAGE = 'letscodewithrajat/spring-boot-demo'
        DOCKER_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"

        // Docker stability settings
        DOCKER_HOST = "unix:///var/run/docker.sock"
        DOCKER_BUILDKIT = "1"
    }

    stages {
        stage('Environment Prep') {
            steps {
                script {
                    // Verify Docker exists and is responsive
                    def dockerReady = sh(script: """
                        ${DOCKER_CMD} --version || exit 1
                        ${DOCKER_CMD} ps >/dev/null 2>&1 || exit 1
                        echo "Using Docker at: ${DOCKER_CMD}"
                    """, returnStatus: true) == 0

                    if (!dockerReady) {
                        error("Docker not properly configured at ${DOCKER_CMD}")
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
            steps {
                script {
                    // Build with explicit retry logic
                    retry(2) {
                        sh """
                            ${DOCKER_CMD} build \
                            -t ${DOCKER_IMAGE}:${DOCKER_TAG} \
                            --build-arg MAVEN_IMAGE=${MAVEN_IMAGE} .
                        """
                    }

                    // Push with credential handling
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            ${DOCKER_CMD} login -u $DOCKER_USER -p $DOCKER_PASS
                            ${DOCKER_CMD} push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            ${DOCKER_CMD} push ${DOCKER_IMAGE}:latest
                        """
                    }

                    // Deployment
                    sh """
                        ${DOCKER_CMD} stop spring-boot-app || true
                        ${DOCKER_CMD} rm spring-boot-app || true
                        ${DOCKER_CMD} run -d \
                            --name spring-boot-app \
                            -p 8080:8080 \
                            ${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                // Ultra-safe cleanup that cannot fail
                try {
                    // File cleanup
                    sh 'rm -rf target/* || echo "Cleanup warning: Failed to remove target files"'

                    // Docker cleanup with absolute path
                    sh """
                        ${DOCKER_CMD} system prune -f || \
                        echo "Cleanup warning: Docker prune failed"
                    """
                } catch (Exception e) {
                    echo "Cleanup error suppressed: ${e.message}"
                }
            }
        }
        success {
            echo "✅ SUCCESS: Application deployed to http://localhost:8080"
            echo "📦 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo "❌ FAILURE: Pipeline failed - check logs"
            // Attempt final cleanup even on failure
            sh "${DOCKER_CMD} system prune -f || true"
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
