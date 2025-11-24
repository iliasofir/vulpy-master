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

                    // Récupérer UID et GID pour éviter les erreurs Docker
                    def uid = sh(script: "id -u", returnStdout: true).trim()
                    def gid = sh(script: "id -g", returnStdout: true).trim()

                    sh """
                        docker run --rm -u ${uid}:${gid} \
                        -v "${WORKSPACE}:/src" \
                        -w /src \
                        python:3.11-slim \
                        bash -c '
                            pip install bandit -q && \
                            mkdir -p "${REPORT_DIR}" && \
                            echo "Scanning with Bandit..." && \
                            bandit -r bad good utils \
                                -f html -o "${REPORT_DIR}/bandit-report.html" || true && \
                            bandit -r bad good utils \
                                -f json -o "${REPORT_DIR}/bandit-report.json" || true && \
                            bandit -r bad good utils \
                                -f txt -o "${REPORT_DIR}/bandit-report.txt" || true && \
                            bandit -r bad good utils \
                                -f csv -o "${REPORT_DIR}/bandit-report.csv" || true && \
                            echo "Files in ${REPORT_DIR}:" && ls -la "${REPORT_DIR}" && \
                            echo "Bandit reports generated"
                        '
                    """

                    // Vérifier que les rapports ont été générés
                    sh "ls -la ${REPORT_DIR}/ || echo 'Report directory empty'"
                    
                    if (fileExists("${REPORT_DIR}/bandit-report.html")) {
                        echo '✓ Rapport HTML généré avec succès'
                    } else {
                        echo '⚠️  Rapport HTML non trouvé'
                    }
                    
                    // Résumé rapide
                    echo '→ Affichage du résumé Bandit:'
                    sh """
                        docker run --rm \
                          -v "${WORKSPACE}:/src" \
                          -w /src \
                          python:3.11-slim \
                          bash -c 'pip install bandit -q && bandit -r bad good utils --severity-level medium || true'
                    """
                    
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
                    archiveArtifacts artifacts: "${REPORT_DIR}/bandit-*", 
                                     allowEmptyArchive: true,
                                     fingerprint: true
                    
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: "${REPORT_DIR}",
                        reportFiles: 'bandit-report.html',
                        reportName: 'Bandit SAST Report',
                        reportTitles: 'Bandit Security Analysis'
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
