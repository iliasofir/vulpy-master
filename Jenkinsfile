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
            
            // Copier les fichiers dans le conteneur au lieu d'utiliser volume mount
            try {
                // Créer et démarrer le conteneur
                sh """
                    docker run -d --name ${containerName} \
                    -w /app \
                    python:3.11-slim \
                    tail -f /dev/null
                """
                
                // Copier le code source dans le conteneur
                echo '→ Copie du code source dans le conteneur...'
                sh "docker cp \${WORKSPACE}/. ${containerName}:/app/"
                
                // Installer Bandit
                sh "docker exec ${containerName} pip install bandit -q"
                
                // Créer dossier pour les rapports dans le conteneur
                sh "docker exec ${containerName} mkdir -p /tmp/reports"
                
                // Vérifier que les fichiers sont copiés
                echo '=== Vérification des fichiers ==='
                sh "docker exec ${containerName} ls -la /app/"
                sh "docker exec ${containerName} find /app -name '*.py' | head -5"
                
                // Scanner avec Bandit
                echo '=== Scanning avec Bandit ==='
                sh """
                    docker exec ${containerName} bandit -r /app/bad /app/good /app/utils \
                        -f html -o /tmp/reports/bandit-report.html || true
                """
                
                sh """
                    docker exec ${containerName} bandit -r /app/bad /app/good /app/utils \
                        -f json -o /tmp/reports/bandit-report.json || true
                """
                
                sh """
                    docker exec ${containerName} bandit -r /app/bad /app/good /app/utils \
                        -f txt -o /tmp/reports/bandit-report.txt || true
                """
                
                sh """
                    docker exec ${containerName} bandit -r /app/bad /app/good /app/utils \
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
                
                if (fileExists("${REPORT_DIR}/bandit-report.json")) {
                    echo '✓ Rapports Bandit générés avec succès!'
                    echo ''
                    echo '┌─────────────────────────────────────────────────────┐'
                    echo '│       📊 RÉSUMÉ DE L\'ANALYSE BANDIT SAST           │'
                    echo '└─────────────────────────────────────────────────────┘'
                    echo ''
                    
                    // Extraire les statistiques avec grep et wc
                    def highSeverity = sh(script: "grep -c '\"issue_severity\": \"HIGH\"' ${REPORT_DIR}/bandit-report.json || echo 0", returnStdout: true).trim()
                    def mediumSeverity = sh(script: "grep -c '\"issue_severity\": \"MEDIUM\"' ${REPORT_DIR}/bandit-report.json || echo 0", returnStdout: true).trim()
                    def lowSeverity = sh(script: "grep -c '\"issue_severity\": \"LOW\"' ${REPORT_DIR}/bandit-report.json || echo 0", returnStdout: true).trim()
                    def totalLoc = sh(script: "grep '\"loc\":' ${REPORT_DIR}/bandit-report.json | grep '_totals' -A1 | tail -1 | grep -o '[0-9]*' | head -1", returnStdout: true).trim()
                    
                    def totalIssues = (highSeverity as Integer) + (mediumSeverity as Integer) + (lowSeverity as Integer)
                    
                    echo "📁 Code scanné:"
                    echo "   • Lignes de code analysées: ${totalLoc}"
                    echo "   • Total vulnérabilités: ${totalIssues}"
                    echo ''
                    echo '🔍 Vulnérabilités par SÉVÉRITÉ:'
                    echo "   🔴 HIGH     : ${highSeverity}"
                    echo "   🟠 MEDIUM   : ${mediumSeverity}"
                    echo "   🟡 LOW      : ${lowSeverity}"
                    echo ''
                    
                    if (totalIssues > 0) {
                        echo "⚠️  TOTAL: ${totalIssues} vulnérabilités détectées"
                        echo ''
                        echo '📄 Consultez le rapport HTML pour tous les détails'
                    } else {
                        echo '✅ Aucune vulnérabilité détectée'
                    }
                    echo ''
                    echo '═════════════════════════════════════════════════════'
                } else {
                    echo '⚠️  Attention: bandit-report.json non trouvé'
                }
                }
            }
        }
        
        stage('📊 Archiver les Rapports Bandit') {
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
            echo ''
            echo '╔═══════════════════════════════════════════════════════╗'
            echo '║   ✅ PIPELINE TERMINÉ AVEC SUCCÈS                     ║'
            echo '╚═══════════════════════════════════════════════════════╝'
            echo ''
            echo '📊 Rapports disponibles dans les artifacts Jenkins'
            echo '📄 Consultez le rapport HTML pour les détails complets'
        }
        failure {
            echo ''
            echo '╔═══════════════════════════════════════════════════════╗'
            echo '║   ❌ PIPELINE ÉCHOUÉ                                  ║'
            echo '╚═══════════════════════════════════════════════════════╝'
            echo ''
            echo '🔍 Vérifiez les logs ci-dessus pour plus de détails'
        }
        always {
            echo ''
            echo '🏁 Pipeline SAST Bandit terminé'
            echo "⏱️  Durée: ${currentBuild.durationString.replace(' and counting', '')}"
        }
    }
}