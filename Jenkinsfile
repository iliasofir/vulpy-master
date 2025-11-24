pipeline {
    agent any
    
    environment {
        // Configuration
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
                    sh "mkdir -p ${REPORT_DIR}"
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
                        # Générer les rapports dans /tmp du conteneur puis copier
                        docker run --rm \
                        -v "${WORKSPACE}:/workspace" \
                        -w /workspace \
                        python:3.11-slim \
                        bash -c '
                            pip install bandit -q && \
                            mkdir -p /tmp/bandit-reports && \
                            echo "Scanning with Bandit..." && \
                            bandit -r bad good utils -f html -o /tmp/bandit-reports/bandit-report.html || true && \
                            bandit -r bad good utils -f json -o /tmp/bandit-reports/bandit-report.json || true && \
                            bandit -r bad good utils -f txt -o /tmp/bandit-reports/bandit-report.txt || true && \
                            bandit -r bad good utils -f csv -o /tmp/bandit-reports/bandit-report.csv || true && \
                            echo "Copying reports to workspace..." && \
                            mkdir -p /workspace/${REPORT_DIR} && \
                            cp -v /tmp/bandit-reports/* /workspace/${REPORT_DIR}/ && \
                            chmod -R 777 /workspace/${REPORT_DIR} && \
                            echo "Reports copied successfully"
                        '
                        
                        # Vérifier depuis Jenkins
                        echo "Vérification finale:"
                        ls -lah ${WORKSPACE}/${REPORT_DIR}/
                    """
                    
                    if (fileExists("${REPORT_DIR}/bandit-report.html")) {
                        echo '✓ Rapports générés et copiés avec succès'
                    } else {
                        echo '⚠️ Attention: Rapport HTML non trouvé'
                    }
                    
                    echo '✓ Analyse SAST Bandit terminée'
                }
            }
        }

        stage('📊 Archiver les Rapports Bandit'){
            steps {
                echo '================================================'
                echo '📊 Archivage des rapports Bandit'
                echo '================================================'
                script {
                    // Vérifier l'existence des fichiers
                    sh "ls -la ${WORKSPACE}/${REPORT_DIR}/ || echo 'Aucun fichier trouvé'"
                    
                    archiveArtifacts artifacts: "${REPORT_DIR}/bandit-*", 
                                     allowEmptyArchive: false,
                                     fingerprint: true
                    
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: "${REPORT_DIR}",
                        reportFiles: 'bandit-report.html',
                        reportName: 'Bandit SAST Report'
                    ])
                    
                    echo '✓ Rapports Bandit archivés avec succès'
                }
            }
        }
    }
    
    post {
        success {
            echo '###############################################'
            echo '#                                             #'
            echo '#   ✓ Scan SAST Bandit terminé avec succès!   #'
            echo '###############################################'
            echo ''
            echo "Rapports Bandit disponibles dans: ${REPORT_DIR}/"
        }
        unstable {
            echo '###############################################'
            echo '#                                             #'
            echo '#   ⚠️  Vulnérabilités détectées par Bandit  #'
            echo '#                                             #'
            echo '###############################################'
        }
        failure {
            echo '###############################################'
            echo '#                                             #'
            echo '#   ✗ Scan Bandit échoué!                    #'
            echo '#                                             #'
            echo '###############################################'
            echo ''
            echo 'Consultez les logs pour plus de détails'
        }
        always {
            echo 'Pipeline SAST Bandit terminé'
        }
    }
}