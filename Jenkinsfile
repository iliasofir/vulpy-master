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
            
            // Créer un conteneur nommé
            def containerName = "bandit-scan-${BUILD_NUMBER}"
            
            try {
                // Créer et démarrer le conteneur
                sh """
                    docker run -d --name ${containerName} \
                    -v "\${WORKSPACE}:/src:ro" \
                    -w /tmp \
                    python:3.11-slim \
                    tail -f /dev/null
                """
                
                // Installer Bandit
                sh "docker exec ${containerName} pip install bandit -q"
                
                // Créer dossier pour les rapports dans le conteneur
                sh "docker exec ${containerName} mkdir -p /tmp/reports"
                
                // Scanner avec Bandit
                echo '=== Scanning avec Bandit ==='
                sh """
                    docker exec ${containerName} bandit -r /src/bad /src/good /src/utils \
                        -f html -o /tmp/reports/bandit-report.html || true
                """
                
                sh """
                    docker exec ${containerName} bandit -r /src/bad /src/good /src/utils \
                        -f json -o /tmp/reports/bandit-report.json || true
                """
                
                sh """
                    docker exec ${containerName} bandit -r /src/bad /src/good /src/utils \
                        -f txt -o /tmp/reports/bandit-report.txt || true
                """
                
                sh """
                    docker exec ${containerName} bandit -r /src/bad /src/good /src/utils \
                        -f csv -o /tmp/reports/bandit-report.csv || true
                """
                
                // Vérifier que les rapports sont créés dans le conteneur
                sh "docker exec ${containerName} ls -lah /tmp/reports/"
                
                // COPIER les rapports depuis le conteneur vers Jenkins
                echo '→ Copie des rapports depuis le conteneur...'
                sh "docker cp ${containerName}:/tmp/reports/. \${WORKSPACE}/${REPORT_DIR}/"
                
            } finally {
                // Nettoyer le conteneur
                sh "docker stop ${containerName} || true"
                sh "docker rm ${containerName} || true"
            }
            
            // Vérifier les rapports dans Jenkins workspace
            echo '→ Vérification des rapports dans Jenkins workspace:'
            sh "ls -lah \${WORKSPACE}/${REPORT_DIR}/"
            
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