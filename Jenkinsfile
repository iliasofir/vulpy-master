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
                        # Créer le répertoire avec permissions ouvertes
                        sudo mkdir -p ${WORKSPACE}/${REPORT_DIR}
                        sudo chmod -R 777 ${WORKSPACE}/${REPORT_DIR}
                        
                        # Exécuter Docker
                        docker run --rm \
                        -v "${WORKSPACE}:/src:rw" \
                        -w /src \
                        --user root \
                        python:3.11-slim \
                        bash -c '
                            pip install bandit -q && \
                            bandit -r bad good utils -f html -o ${REPORT_DIR}/bandit-report.html || true && \
                            bandit -r bad good utils -f json -o ${REPORT_DIR}/bandit-report.json || true && \
                            bandit -r bad good utils -f txt -o ${REPORT_DIR}/bandit-report.txt || true && \
                            bandit -r bad good utils -f csv -o ${REPORT_DIR}/bandit-report.csv || true && \
                            chmod -R 777 ${REPORT_DIR}
                        '
                        
                        # Forcer les permissions après Docker
                        sudo chmod -R 755 ${WORKSPACE}/${REPORT_DIR}
                        sudo chown -R jenkins:jenkins ${WORKSPACE}/${REPORT_DIR}
                        
                        echo "Fichiers créés:"
                        ls -lah ${WORKSPACE}/${REPORT_DIR}/
                    """
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