pipeline {
    agent any
    
    environment {
        PROJECT_NAME = 'vulpy'
        REPORT_DIR = 'security-reports'
        TRIVY_CACHE_DIR = "/tmp/trivycache"
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
                
                // Scanner avec Bandit (seulement HTML et JSON)
                echo '=== Scanning avec Bandit ==='
                sh """
                    docker exec ${containerName} bandit -r /app/bad /app/good /app/utils \
                        -f html -o /tmp/reports/bandit-report.html -q || true
                """
                
                sh """
                    docker exec ${containerName} bandit -r /app/bad /app/good /app/utils \
                        -f json -o /tmp/reports/bandit-report.json -q || true
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
                    // Extraire les statistiques
                    def highSeverity = sh(script: "grep -c '\"issue_severity\": \"HIGH\"' ${REPORT_DIR}/bandit-report.json || echo 0", returnStdout: true).trim()
                    def mediumSeverity = sh(script: "grep -c '\"issue_severity\": \"MEDIUM\"' ${REPORT_DIR}/bandit-report.json || echo 0", returnStdout: true).trim()
                    def lowSeverity = sh(script: "grep -c '\"issue_severity\": \"LOW\"' ${REPORT_DIR}/bandit-report.json || echo 0", returnStdout: true).trim()
                    def totalLoc = sh(script: "grep '\"loc\":' ${REPORT_DIR}/bandit-report.json | grep '_totals' -A1 | tail -1 | grep -o '[0-9]*' | head -1", returnStdout: true).trim()
                    def totalIssues = (highSeverity as Integer) + (mediumSeverity as Integer) + (lowSeverity as Integer)
                    
                    echo ''
                    echo '═══════════════════════════════════════════════════════'
                    echo "📊 RÉSUMÉ: ${totalIssues} vulnérabilités | ${totalLoc} lignes analysées"
                    echo "   🔴 HIGH: ${highSeverity}  🟠 MEDIUM: ${mediumSeverity}  🟡 LOW: ${lowSeverity}"
                    echo '═══════════════════════════════════════════════════════'
                    echo ''
                } else {
                    echo '⚠️  Attention: bandit-report.json non trouvé'
                }
                }
            }
        }


        stage('🔒 SCA - Trivy') {
            steps {
                echo '================================================'
                echo '🔒 Analyse complète SCA avec Trivy'
                echo '================================================'
                script {
                    // 1) Scanner requirements.txt (dépendances directes)
                    echo '→ 1/5 Scan requirements.txt...'
                    sh """
                        docker run --rm \
                        -v "${WORKSPACE}:/src" \
                        aquasec/trivy:0.53.0 fs /src/requirements.txt \
                        --format json \
                        --quiet > ${WORKSPACE}/${REPORT_DIR}/trivy-requirements.json || true
                    """
                    
                    // 2) Scanner toutes les dépendances Python (directes + transitives)
                    echo '→ 2/5 Scan toutes dépendances Python (directes + transitives)...'
                    sh """
                        docker run --rm \
                        -v "${WORKSPACE}:/src" \
                        aquasec/trivy:0.53.0 fs /src \
                        --scanners vuln \
                        --format json \
                        --severity HIGH,CRITICAL \
                        --quiet > ${WORKSPACE}/${REPORT_DIR}/trivy-dependencies.json || true
                    """
                    
                    // 3) Scanner tous les fichiers du projet
                    echo '→ 3/5 Scan fichiers du projet...'
                    sh """
                        docker run --rm \
                        -v "${WORKSPACE}:/src" \
                        aquasec/trivy:0.53.0 fs /src \
                        --scanners misconfig,secret \
                        --format json \
                        --quiet > ${WORKSPACE}/${REPORT_DIR}/trivy-files.json || true
                    """
                    
                    // 4) Analyse Supply Chain complète
                    echo '→ 4/5 Analyse Supply Chain...'
                    sh """
                        docker run --rm \
                        -v "${WORKSPACE}:/src" \
                        aquasec/trivy:0.53.0 fs /src \
                        --format cyclonedx \
                        --quiet > ${WORKSPACE}/${REPORT_DIR}/trivy-sbom.json || true
                    """
                    
                    // 5) Rapport HTML consolidé
                    echo '→ 5/5 Génération rapport HTML...'
                    sh """
                        docker run --rm \
                        -v "${WORKSPACE}:/src" \
                        aquasec/trivy:0.53.0 fs /src \
                        --format template \
                        --template '@contrib/html.tpl' \
                        --quiet > ${WORKSPACE}/${REPORT_DIR}/trivy-report.html || true
                    """
                    
                    echo ''
                    echo '→ Vérification des rapports Trivy:'
                    sh "ls -lah ${WORKSPACE}/${REPORT_DIR}/trivy* || echo 'Aucun rapport Trivy trouvé'"
                    
                    // Analyser les résultats consolidés
                    if (fileExists("${REPORT_DIR}/trivy-dependencies.json")) {
                        def criticalCount = sh(script: "grep -c '\"Severity\":\"CRITICAL\"' ${REPORT_DIR}/trivy-dependencies.json || echo 0", returnStdout: true).trim()
                        def highCount = sh(script: "grep -c '\"Severity\":\"HIGH\"' ${REPORT_DIR}/trivy-dependencies.json || echo 0", returnStdout: true).trim()
                        
                        def totalCritical = criticalCount as Integer
                        def totalHigh = highCount as Integer
                        def totalVuln = totalCritical + totalHigh
                        
                        echo ''
                        echo '═══════════════════════════════════════════════════════'
                        echo "🔒 TRIVY SCA: ${totalVuln} vulnérabilités HIGH/CRITICAL"
                        echo "   💀 CRITICAL: ${totalCritical}  🔴 HIGH: ${totalHigh}"
                        echo '✓ Rapports générés:'
                        echo '   → trivy-requirements.json (dépendances directes)'
                        echo '   → trivy-dependencies.json (directes + transitives)'
                        echo '   → trivy-files.json (fichiers projet)'
                        echo '   → trivy-sbom.json (supply chain)'
                        echo '   → trivy-report.html (rapport complet)'
                        echo '═══════════════════════════════════════════════════════'
                        echo ''
                        
                        if (totalCritical > 0) {
                            echo "⚠️  ATTENTION: ${totalCritical} vulnérabilités CRITICAL détectées!"
                            echo '📄 Consultez trivy-report.html pour détails'
                        }
                    } else {
                        echo '⚠️  Attention: rapports Trivy non trouvés'
                    }
                }
            }
        }


        
        stage('📊 Archiver les Rapports') {
            steps {
                echo '================================================'
                echo '📊 Archivage et publication des rapports'
                echo '================================================'
                script {
                    sh "ls -la ${WORKSPACE}/${REPORT_DIR}/"
                    
                    // Archiver tous les rapports
                    archiveArtifacts artifacts: "${REPORT_DIR}/*", 
                                     allowEmptyArchive: true,
                                     fingerprint: true
                    
                    // Publier rapport Bandit HTML
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: "${REPORT_DIR}",
                        reportFiles: 'bandit-report.html',
                        reportName: '📊 Bandit SAST Report'
                    ])
                    
                    // Publier rapport Trivy HTML
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: "${REPORT_DIR}",
                        reportFiles: 'trivy-report.html',
                        reportName: '🔒 Trivy SCA Report'
                    ])
                    
                    echo '✓ Rapports publiés avec succès'
                    echo '  → Bandit SAST (SAST)'
                    echo '  → Trivy SCA (Supply Chain)'
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline terminé avec succès'
        }
        failure {
            echo '❌ Pipeline échoué'
        }
        always {
            echo "⏱️  Durée: ${currentBuild.durationString.replace(' and counting', '')}"
        }
    }
}