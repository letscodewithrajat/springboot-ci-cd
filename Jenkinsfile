pipeline {
    agent any
    options {
        skipStagesAfterUnstable()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        // Dynamic path resolution that always works
        DOCKER_CMD = sh(script: '''
            [ -x "/usr/local/bin/docker" ] && echo "/usr/local/bin/docker" || \
            [ -x "/opt/homebrew/bin/docker" ] && echo "/opt/homebrew/bin/docker" || \
            which docker || echo "docker"
        ''', returnStdout: true).trim()

        PATH = "/usr/local/bin:/opt/homebrew/bin:${env.PATH}"
        MAVEN_IMAGE = "maven:3.8.7-eclipse-temurin-17"
        DOCKER_IMAGE = 'letscodewithrajat/spring-boot-demo'
        DOCKER_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    }

    stages {
        stage('Environment Verification') {
            steps {
                script {
                    // Verify Docker is truly available
                    def dockerReady = sh(script: """
                        echo "Checking Docker at: ${DOCKER_CMD}"
                        ${DOCKER_CMD} --version && ${DOCKER_CMD} ps
                    """, returnStatus: true) == 0

                    if (!dockerReady) {
                        error("Docker not properly configured")
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
                    // Build with absolute path
                    sh "${DOCKER_CMD} build -t ${DOCKER_IMAGE}:${DOCKER_TAG} --build-arg MAVEN_IMAGE=${MAVEN_IMAGE} ."

                    // Push with credentials
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${DOCKER_IMAGE}:latest").push()
                    }

                    // Deploy with health check
                    sh """
                        ${DOCKER_CMD} stop spring-boot-app || true
                        ${DOCKER_CMD} rm spring-boot-app || true
                        ${DOCKER_CMD} run -d --name spring-boot-app -p 8080:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        sleep 5
                        ${DOCKER_CMD} ps --filter name=spring-boot-app --format '{{.Status}}' | grep -q 'Up' || exit 1
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                // Never-fail cleanup
                sh """
                    # File cleanup
                    rm -rf target/* || echo "File cleanup warning"

                    # Docker cleanup that cannot fail
                    ${DOCKER_CMD} system prune -f || \
                    echo "Docker cleanup warning"

                    # Final verification
                    echo "=== Pipeline Completed ==="
                    echo "Docker Status:"
                    ${DOCKER_CMD} ps -a || true
                """
            }
        }

        success {
            echo "✅ SUCCESS: All stages completed"
            echo "🌐 Application: http://localhost:8080"
            echo "🐳 Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }

        failure {
            echo "❌ FAILURE: Check specific stage logs"
            // Additional diagnostics
            sh """
                echo "=== Failure Diagnostics ==="
                ${DOCKER_CMD} version || true
                ${DOCKER_CMD} info || true
            """
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
