pipeline {
    agent any
    options {
        skipStagesAfterUnstable()
        timeout(time: 30, unit: 'MINUTES')
        retry(2) // Retry entire pipeline on failure
    }

    environment {
        // Absolute paths for macOS (both Intel and Apple Silicon)
        DOCKER_PATH = "/usr/local/bin/docker:/opt/homebrew/bin/docker"
        PATH = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

        // Docker configuration
        MAVEN_IMAGE = "maven:3.8.7-eclipse-temurin-17"
        DOCKER_REGISTRY = 'https://registry.hub.docker.com'
        DOCKER_IMAGE = 'letscodewithrajat/spring-boot-demo'
        DOCKER_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"

        // Ensure Docker context is stable
        DOCKER_HOST = "unix:///var/run/docker.sock"
        DOCKER_BUILDKIT = "1"
    }

    stages {
        stage('Verify Environment') {
            steps {
                script {
                    // Verify Docker is available and responsive
                    def dockerReady = sh(script: '''
                        which docker || exit 1
                        docker ps >/dev/null 2>&1 || exit 1
                        echo "Docker ready at: $(which docker)"
                    ''', returnStatus: true) == 0

                    if (!dockerReady) {
                        error("Docker not properly configured")
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    try {
                        // Explicitly use full docker path
                        sh """
                            /usr/local/bin/docker build \
                            -t ${DOCKER_IMAGE}:${DOCKER_TAG} \
                            --build-arg MAVEN_IMAGE=${MAVEN_IMAGE} .
                        """
                    } catch (Exception e) {
                        echo "Docker build failed, restarting Docker Desktop..."
                        sh 'osascript -e "quit app \\"Docker\\"" && sleep 5 && open -a Docker && sleep 15'
                        error("Docker build failed after restart: ${e.message}")
                    }
                }
            }
        }

        stage('Docker Push') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            # Explicit login with retry
                            for i in {1..3}; do
                                /usr/local/bin/docker login -u $DOCKER_USER -p $DOCKER_PASS ${DOCKER_REGISTRY} && break
                                sleep 5
                            done

                            /usr/local/bin/docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            /usr/local/bin/docker push ${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh """
                        /usr/local/bin/docker stop spring-boot-app || true
                        /usr/local/bin/docker rm spring-boot-app || true
                        /usr/local/bin/docker run -d \
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
                // Safe cleanup that won't fail
                sh '''
                    rm -rf target/* || true
                    docker system prune -f || true
                '''
            }
        }
        success {
            echo "✅ SUCCESS: App running at http://localhost:8080"
            echo "📦 Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo "❌ FAILURE: Pipeline failed at ${currentBuild.currentResult}"
            sh 'docker system prune -f || true'
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
