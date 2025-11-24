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
                -v "${WORKSPACE}:/app" \
                -w /app \
                python:3.11-slim \
                bash -c '
                    pip install bandit -q
                    
                    echo "=== Contenu du workspace ==="
                    ls -la /app/
                    
                    echo "=== Vérification des dossiers à scanner ==="
                    ls -ld /app/bad /app/good /app/utils 2>/dev/null || echo "Dossiers non trouvés!"
                    
                    echo "=== Création répertoire rapports ==="
                    mkdir -p /app/${REPORT_DIR}
                    
                    echo "=== Exécution Bandit sur les fichiers Python trouvés ==="
                    
                    # Scanner tous les fichiers .py récursivement
                    find /app -name "*.py" -type f > /tmp/python_files.txt
                    echo "Fichiers Python trouvés:"
                    cat /tmp/python_files.txt
                    
                    # Exécuter Bandit sur TOUT le workspace
                    echo "=== Scanning avec Bandit ==="
                    bandit -r /app/bad /app/good /app/utils \
                        -f html -o /app/${REPORT_DIR}/bandit-report.html 2>&1 || true
                    
                    bandit -r /app/bad /app/good /app/utils \
                        -f json -o /app/${REPORT_DIR}/bandit-report.json 2>&1 || true
                    
                    bandit -r /app/bad /app/good /app/utils \
                        -f txt -o /app/${REPORT_DIR}/bandit-report.txt 2>&1 || true
                    
                    bandit -r /app/bad /app/good /app/utils \
                        -f csv -o /app/${REPORT_DIR}/bandit-report.csv 2>&1 || true
                    
                    echo "=== Rapports générés ==="
                    ls -lah /app/${REPORT_DIR}/
                    
                    echo "=== Permissions ==="
                    chmod -R 777 /app/${REPORT_DIR}
                    
                    echo "=== Résumé rapide ==="
                    bandit -r /app/bad /app/good /app/utils --severity-level low 2>&1 || true
                '
            """
            
            // Vérification finale
            sh """
                echo "=== Vérification finale depuis Jenkins ==="
                ls -lah ${WORKSPACE}/${REPORT_DIR}/
                
                if [ -f "${WORKSPACE}/${REPORT_DIR}/bandit-report.html" ]; then
                    echo "✓ Rapport HTML trouvé"
                    wc -l ${WORKSPACE}/${REPORT_DIR}/bandit-report.html
                else
                    echo "✗ Rapport HTML non trouvé"
                fi
            """
            
            if (fileExists("${REPORT_DIR}/bandit-report.html")) {
                echo '✓ Rapports Bandit générés avec succès'
            } else {
                echo '⚠️ Rapports non générés'
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