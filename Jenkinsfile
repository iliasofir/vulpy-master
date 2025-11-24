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
            
            sh """
                docker run --rm \
                -v "\${WORKSPACE}:/workspace" \
                -w /workspace \
                python:3.11-slim \
                bash -c '
                    pip install bandit -q
                    mkdir -p /workspace/${REPORT_DIR}
                    
                    echo "=== Scanning avec Bandit ==="
                    bandit -r . \
                        -x "./.git,./venv,./node_modules" \
                        -f html -o /workspace/${REPORT_DIR}/bandit-report.html || true
                    
                    bandit -r . \
                        -x "./.git,./venv,./node_modules" \
                        -f json -o /workspace/${REPORT_DIR}/bandit-report.json || true
                    
                    bandit -r . \
                        -x "./.git,./venv,./node_modules" \
                        -f txt -o /workspace/${REPORT_DIR}/bandit-report.txt || true
                    
                    bandit -r . \
                        -x "./.git,./venv,./node_modules" \
                        -f csv -o /workspace/${REPORT_DIR}/bandit-report.csv || true
                    
                    echo "=== Rapports générés ==="
                    ls -lah /workspace/${REPORT_DIR}/
                '
            """
            
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