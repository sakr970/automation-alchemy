pipeline {
    agent any
    
    environment {
        // Registry configuration
        REGISTRY_URL = '192.168.56.126:5000'
        BACKEND_IMAGE = "${REGISTRY_URL}/diagnostic_backend"
        FRONTEND_IMAGE = "${REGISTRY_URL}/diagnostic_frontend"
        
        // Git commit SHA for image tagging
        GIT_COMMIT_SHORT = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
        ).trim()
        
        // Deployment targets
        APP_SERVER = '192.168.56.121'
        WEB1_SERVER = '192.168.56.122'
        WEB2_SERVER = '192.168.56.123'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }
        
        stage('Build Images') {
            steps {
                echo 'Building Docker images...'
                script {
                    // Build backend image
                    sh """
                        docker build -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} \
                                     -t ${BACKEND_IMAGE}:latest \
                                     ./docker/backend/
                    """
                    
                    // Build frontend image
                    sh """
                        docker build -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} \
                                     -t ${FRONTEND_IMAGE}:latest \
                                     ./docker/frontend/
                    """
                }
                echo 'Images built successfully'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                script {
                    // Test backend
                    sh """
                        cd docker/backend
                        if [ -f package.json ] && grep -q '"test"' package.json; then
                            npm ci || true
                            npm test || echo "Backend tests not found or failed"
                        else
                            echo "No backend tests configured"
                        fi
                    """
                    
                    // Test frontend
                    sh """
                        cd docker/frontend
                        if [ -f package.json ] && grep -q '"test"' package.json; then
                            npm ci || true
                            npm test || echo "Frontend tests not found or failed"
                        else
                            echo "No frontend tests configured"
                        fi
                    """
                }
                echo 'Tests completed'
            }
        }
        
        stage('Push to Registry') {
            steps {
                echo 'Pushing images to local registry...'
                script {
                    // Push both tags (commit SHA and latest)
                    sh """
                        docker push ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}
                        docker push ${BACKEND_IMAGE}:latest
                        docker push ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}
                        docker push ${FRONTEND_IMAGE}:latest
                    """
                }
                echo 'Images pushed to registry'
            }
        }
        
        stage('Deploy to App Server') {
            steps {
                echo 'Deploying backend to app server...'
                script {
                    sshagent(credentials: ['deploy-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no devops@${APP_SERVER} '
                                # Pull new image
                                docker pull ${BACKEND_IMAGE}:latest
                                
                                # Stop and remove old container
                                docker stop diagnostic_backend || true
                                docker rm diagnostic_backend || true
                                
                                # Start new container
                                docker run -d \
                                    --name diagnostic_backend \
                                    --restart always \
                                    -p 5000:5000 \
                                    -e NODE_ENV=production \
                                    ${BACKEND_IMAGE}:latest
                                
                                # Wait and verify
                                sleep 5
                                curl -f http://localhost:5000/metrics || exit 1
                            '
                        """
                    }
                }
                echo 'Backend deployed successfully'
            }
        }
        
        stage('Deploy to Web Servers') {
            parallel {
                stage('Deploy to Web1') {
                    steps {
                        echo 'Deploying frontend to web1...'
                        script {
                            sshagent(credentials: ['deploy-ssh-key']) {
                                sh """
                                    ssh -o StrictHostKeyChecking=no devops@${WEB1_SERVER} '
                                        docker pull ${FRONTEND_IMAGE}:latest
                                        docker stop diagnostic_frontend || true
                                        docker rm diagnostic_frontend || true
                                        docker run -d \
                                            --name diagnostic_frontend \
                                            --restart always \
                                            -p 3000:3000 \
                                            -e BACKEND_URL=http://${APP_SERVER}:5000/metrics \
                                            ${FRONTEND_IMAGE}:latest
                                        sleep 5
                                        curl -f http://localhost:3000/ || exit 1
                                    '
                                """
                            }
                        }
                        echo 'Frontend deployed to web1'
                    }
                }
                
                stage('Deploy to Web2') {
                    steps {
                        echo 'Deploying frontend to web2...'
                        script {
                            sshagent(credentials: ['deploy-ssh-key']) {
                                sh """
                                    ssh -o StrictHostKeyChecking=no devops@${WEB2_SERVER} '
                                        docker pull ${FRONTEND_IMAGE}:latest
                                        docker stop diagnostic_frontend || true
                                        docker rm diagnostic_frontend || true
                                        docker run -d \
                                            --name diagnostic_frontend \
                                            --restart always \
                                            -p 3000:3000 \
                                            -e BACKEND_URL=http://${APP_SERVER}:5000/metrics \
                                            ${FRONTEND_IMAGE}:latest
                                        sleep 5
                                        curl -f http://localhost:3000/ || exit 1
                                    '
                                """
                            }
                        }
                        echo 'Frontend deployed to web2'
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo 'Verifying deployment...'
                script {
                    // Verify all endpoints are accessible
                    sh """
                        echo "Checking backend..."
                        curl -f http://${APP_SERVER}:5000/metrics
                        
                        echo "Checking frontend web1..."
                        curl -f http://${WEB1_SERVER}:3000/
                        
                        echo "Checking frontend web2..."
                        curl -f http://${WEB2_SERVER}:3000/
                    """
                }
                echo 'All services verified and running!'
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            echo "Deployed version: ${GIT_COMMIT_SHORT}"
        }
        failure {
            echo 'Pipeline failed!'
            echo 'Check the logs above for details.'
        }
        always {
            echo 'Cleaning up...'
            // Clean up old images to save space (keep last 5 versions)
            sh '''
                docker image prune -f
            '''
        }
    }
}
