pipeline {
    agent any
    options {
        retry(3)  // Auto-retry on transient failures
        timeout(time: 30, unit: 'MINUTES')
    }
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

        // Path configuration (M1/M2 Mac optimized)
        PATH = "/opt/homebrew/bin:/usr/local/bin:$PATH"
        DOCKER_HOST = "unix:///var/run/docker.sock"
        DOCKER_BUILDKIT = "1"  // Enable modern buildkit
    }

    stages {
        // Stage 1: Verify environment
        stage('Verify Environment') {
            steps {
                sh '''
                    echo "=== Tool Versions ==="
                    java -version
                    mvn --version
                    git --version
                    docker --version
                    echo "=== Docker Info ==="
                    docker info
                '''
            }
        }

        // Stage 2: Checkout code
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    extensions: [],
                    userRemoteConfigs: [[url: 'https://github.com/letscodewithrajat/springboot-ci-cd.git']]
                ])
            }
        }

        // Stage 3: Build and test
        stage('Build and Test') {
            steps {
                sh 'mvn clean package'
            }
            post {
                success {
                    archiveArtifacts 'target/*.jar'
                }
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        // Stage 4: Docker operations with error handling
        stage('Docker Operations') {
            steps {
                script {
                    try {
                        // Build image
                        docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}", "--build-arg MAVEN_IMAGE=${MAVEN_IMAGE} .")

                        // Push to registry
                        docker.withRegistry("${DOCKER_REGISTRY}", 'docker-hub-creds') {
                            docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                            docker.image("${DOCKER_IMAGE}:latest").push()
                        }

                        // Deploy locally
                        sh '''
                            docker stop spring-boot-app || true
                            docker rm spring-boot-app || true
                            docker run -d \
                                --name spring-boot-app \
                                -p 8080:8080 \
                                ${DOCKER_IMAGE}:${DOCKER_TAG}
                        '''
                    } catch (Exception e) {
                        echo "Docker operation failed: ${e.message}"
                        sh 'docker system prune -f || true'  // Cleanup on failure
                        error("Docker pipeline stage failed")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline SUCCESS - App running at http://localhost:8080"
            echo "📦 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo "❌ Pipeline FAILED - Check logs for errors"
            sh 'docker system prune -f || true'  // Cleanup on failure
        }
        always {
            // Optional: Add cleanup of temporary files
            sh 'rm -rf target/* || true'
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
