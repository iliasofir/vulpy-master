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

                // Créer le répertoire avec les bonnes permissions
                sh "mkdir -p ${WORKSPACE}/${REPORT_DIR}"

                sh """
                    docker run --rm \
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
                        echo "Files created in container:" && \
                        ls -la "${REPORT_DIR}/" && \
                        echo "Changing permissions..." && \
                        chmod -R 777 "${REPORT_DIR}" && \
                        chown -R $(stat -c "%u:%g" /src) "${REPORT_DIR}" || true
                    '
             """

            // Vérifier APRÈS Docker depuis Jenkins
            echo '→ Vérification des fichiers créés:'
            sh """
                echo "Contenu du répertoire ${REPORT_DIR} depuis Jenkins:"
                ls -lah ${WORKSPACE}/${REPORT_DIR}/ || echo "Répertoire vide!"
                echo ""
                echo "Permissions du répertoire:"
                ls -ld ${WORKSPACE}/${REPORT_DIR}/
            """
            
            if (fileExists("${WORKSPACE}/${REPORT_DIR}/bandit-report.html")) {
                echo '✓ Rapport HTML généré avec succès'
            } else {
                echo '⚠️  Rapport HTML non trouvé'
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
                    // Utiliser le chemin complet
                    def reportPath = "${WORKSPACE}/${REPORT_DIR}"
                    
                    // Vérifier l'existence des fichiers
                    sh "ls -la ${reportPath}/ || echo 'Aucun fichier trouvé'"
                    
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