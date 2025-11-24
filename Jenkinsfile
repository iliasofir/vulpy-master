pipeline {
    agent any
    
    environment {
        PROJECT_NAME = 'vulpy'
        REPORT_DIR = 'security-reports'
    }
    
    stages {
        stage('🔧 Préparation Environnement') {
            steps {
                echo '================================================'
                echo '🔧 Préparation de l\'environnement'
                echo '================================================'
                script {
                    sh "mkdir -p ${WORKSPACE}/${REPORT_DIR}"
                    sh "chmod -R 777 ${WORKSPACE}/${REPORT_DIR}"
                    sh 'docker --version || echo "Docker not found!"'
                    echo '✓ Environnement préparé'
                }
            }
        }

        stage('📁 Vérifier fichiers Python') {
            steps {
                echo "Listing Python files in workspace:"
                sh 'find . -name "*.py"'
            }
        }
        
       stage('🔍 SAST - Bandit') {
    steps {
        echo '================================================'
        echo '🔍 Analyse statique du code avec Bandit'
        echo '================================================'
        script {
            echo '→ Exécution de Bandit via Docker...'
            
            // Créer un conteneur temporaire avec nom
            def containerId = sh(
                script: """
                    docker run -d \
                    -v "\${WORKSPACE}:/workspace:rw" \
                    -w /workspace \
                    python:3.11-slim \
                    tail -f /dev/null
                """,
                returnStdout: true
            ).trim()
            
            echo "Container ID: ${containerId}"
            
            try {
                // Installer Bandit dans le conteneur
                sh "docker exec ${containerId} pip install bandit -q"
                
                // Créer le dossier reports
                sh "docker exec ${containerId} mkdir -p /workspace/${REPORT_DIR}"
                
                // Scanner avec Bandit
                echo '=== Scanning avec Bandit ==='
                sh """
                    docker exec ${containerId} bandit -r /workspace \
                        -x '/workspace/.git,/workspace/venv,/workspace/node_modules' \
                        -f html -o /workspace/${REPORT_DIR}/bandit-report.html || true
                """
                
                sh """
                    docker exec ${containerId} bandit -r /workspace \
                        -x '/workspace/.git,/workspace/venv,/workspace/node_modules' \
                        -f json -o /workspace/${REPORT_DIR}/bandit-report.json || true
                """
                
                sh """
                    docker exec ${containerId} bandit -r /workspace \
                        -x '/workspace/.git,/workspace/venv,/workspace/node_modules' \
                        -f txt -o /workspace/${REPORT_DIR}/bandit-report.txt || true
                """
                
                sh """
                    docker exec ${containerId} bandit -r /workspace \
                        -x '/workspace/.git,/workspace/venv,/workspace/node_modules' \
                        -f csv -o /workspace/${REPORT_DIR}/bandit-report.csv || true
                """
                
                // Vérifier les rapports dans le conteneur
                sh "docker exec ${containerId} ls -lah /workspace/${REPORT_DIR}/"
                
            } finally {
                // Arrêter et supprimer le conteneur
                sh "docker stop ${containerId} || true"
                sh "docker rm ${containerId} || true"
            }
            
            echo '→ Vérification des rapports dans Jenkins workspace:'
            sh "ls -lah \${WORKSPACE}/${REPORT_DIR}/ || echo 'Dossier vide'"
            
            if (fileExists("${REPORT_DIR}/bandit-report.html")) {
                echo '✓ Rapports Bandit générés avec succès!'
            } else {
                echo '⚠️  Attention: bandit-report.html non trouvé'
            }
        }
    }
}

        stage('📊 Archiver les Rapports Bandit'){
            steps {
                echo '================================================'
                echo '📊 Archivage des rapports Bandit'
                echo '================================================'
                script {
                    sh "ls -la ${WORKSPACE}/${REPORT_DIR}/"
                    
                    archiveArtifacts artifacts: "${REPORT_DIR}/*", 
                                     allowEmptyArchive: true,
                                     fingerprint: true
                    
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: "${REPORT_DIR}",
                        reportFiles: 'bandit-report.html',
                        reportName: 'Bandit SAST Report'
                    ])
                    
                    echo '✓ Archivage terminé'
                }
            }
        }
    }
    
    post {
        success {
            echo '✓ Pipeline terminé avec succès!'
        }
        failure {
            echo '✗ Pipeline échoué - Vérifiez les logs'
        }
        always {
            echo 'Pipeline SAST Bandit terminé'
        }
    }
}