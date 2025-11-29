pipeline {
    agent any
    
    environment {
        PROJECT_NAME = 'vulpy'
        REPORT_DIR = 'security-reports'
        TRIVY_CACHE_DIR = "trivy-cache"
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
                    echo '→ Préparation conteneur Trivy...'
                    
                    def trivyContainer = "trivy-scan-${BUILD_NUMBER}"
                    
                    try {
                        // Créer volume pour cache
                        sh "docker volume create ${TRIVY_CACHE_DIR} || true"
                        
                        // Créer conteneur Trivy persistent avec tail (plus fiable que sleep)
                        sh """
                            docker run -d --name ${trivyContainer} \
                            -v ${TRIVY_CACHE_DIR}:/root/.cache \
                            --entrypoint /bin/sh \
                            aquasec/trivy:0.53.0 \
                            -c 'tail -f /dev/null'
                        """
                        
                        // Vérifier que le conteneur tourne
                        sh "docker ps | grep ${trivyContainer}"
                        
                        // Créer dossier workspace dans conteneur
                        sh "docker exec ${trivyContainer} mkdir -p /workspace"
                        
                        // Copier code source
                        echo '→ Copie du code source dans le conteneur...'
                        sh "docker cp \${WORKSPACE}/. ${trivyContainer}:/workspace/"
                        
                        // Créer dossier rapports
                        sh "docker exec ${trivyContainer} mkdir -p /tmp/trivy-reports"
                        
                        echo '=== Vérification des fichiers ==='
                        sh "docker exec ${trivyContainer} ls -la /workspace/"
                        sh "docker exec ${trivyContainer} test -f /workspace/requirements.txt && echo '✓ requirements.txt trouvé' || echo '✗ requirements.txt manquant'"
                        
                        // 1) Scan requirements.txt
                        echo '→ 1/5 Scan requirements.txt...'
                        sh """
                            docker exec ${trivyContainer} trivy fs /workspace/requirements.txt \
                            --scanners vuln \
                            --format json \
                            -o /tmp/trivy-reports/trivy-requirements.json || true
                        """
                        
                        // 2) Scan dépendances (directes + transitives)
                        echo '→ 2/5 Scan dépendances Python (directes + transitives)...'
                        sh """
                            docker exec ${trivyContainer} trivy fs /workspace \
                            --scanners vuln \
                            --format json \
                            --severity HIGH,CRITICAL \
                            -o /tmp/trivy-reports/trivy-dependencies.json || true
                        """
                        
                        // 3) Scan fichiers projet (secrets, misconfig)
                        echo '→ 3/5 Scan fichiers projet (secrets, misconfig)...'
                        sh """
                            docker exec ${trivyContainer} trivy fs /workspace \
                            --scanners misconfig,secret \
                            --format json \
                            -o /tmp/trivy-reports/trivy-files.json || true
                        """
                        
                        // 4) SBOM Supply Chain
                        echo '→ 4/5 Génération SBOM Supply Chain...'
                        sh """
                            docker exec ${trivyContainer} trivy fs /workspace \
                            --format cyclonedx \
                            -o /tmp/trivy-reports/trivy-sbom.json || true
                        """
                        
                        // 5) Rapport HTML
                        echo '→ 5/5 Génération rapport HTML complet...'
                        sh """
                            docker exec ${trivyContainer} trivy fs /workspace \
                            --format template \
                            --template '@contrib/html.tpl' \
                            --quiet \
                            -o /tmp/trivy-reports/trivy-report.html || true
                        """
                        
                        // Vérifier rapports dans conteneur
                        sh "docker exec ${trivyContainer} ls -lah /tmp/trivy-reports/"
                        
                        // Copier rapports vers Jenkins
                        echo '→ Copie des rapports vers Jenkins workspace...'
                        sh "docker cp ${trivyContainer}:/tmp/trivy-reports/. \${WORKSPACE}/${REPORT_DIR}/"
                        
                    } finally {
                        // Nettoyer conteneur
                        sh "docker stop ${trivyContainer} || true"
                        sh "docker rm ${trivyContainer} || true"
                    }
                    
                    // Vérifier rapports dans Jenkins
                    echo '→ Vérification des rapports Trivy:'
                    sh "ls -lah \${WORKSPACE}/${REPORT_DIR}/trivy* || echo 'Aucun rapport Trivy trouvé'"
                    
                    // Analyser résultats
                    if (fileExists("${REPORT_DIR}/trivy-dependencies.json")) {
                        // Compter TOUTES les vulnérabilités dans les fichiers Trivy
                        def criticalReq = sh(script: "grep -c '\"Severity\": \"CRITICAL\"' ${REPORT_DIR}/trivy-requirements.json 2>/dev/null || echo 0", returnStdout: true).trim().split('\n')[0] as Integer
                        def highReq = sh(script: "grep -c '\"Severity\": \"HIGH\"' ${REPORT_DIR}/trivy-requirements.json 2>/dev/null || echo 0", returnStdout: true).trim().split('\n')[0] as Integer
                        def criticalDep = sh(script: "grep -c '\"Severity\": \"CRITICAL\"' ${REPORT_DIR}/trivy-dependencies.json 2>/dev/null || echo 0", returnStdout: true).trim().split('\n')[0] as Integer
                        def highDep = sh(script: "grep -c '\"Severity\": \"HIGH\"' ${REPORT_DIR}/trivy-dependencies.json 2>/dev/null || echo 0", returnStdout: true).trim().split('\n')[0] as Integer
                        
                        def criticalCount = criticalReq + criticalDep
                        def highCount = highReq + highDep
                        def totalVuln = criticalCount + highCount
                        
                        echo ''
                        echo '═══════════════════════════════════════════════════════'
                        echo "🔒 TRIVY SCA: ${totalVuln} vulnérabilités HIGH/CRITICAL détectées"
                        echo "   💀 CRITICAL: ${criticalCount} (requirements: ${criticalReq} + dependencies: ${criticalDep})"
                        echo "   🔴 HIGH: ${highCount} (requirements: ${highReq} + dependencies: ${highDep})"
                        echo '✓ Rapports générés:'
                        echo '   → trivy-requirements.json (dépendances directes)'
                        echo '   → trivy-dependencies.json (directes + transitives)'
                        echo '   → trivy-files.json (fichiers projet)'
                        echo '   → trivy-sbom.json (supply chain)'
                        echo '   → trivy-report.html (rapport complet)'
                        echo '═══════════════════════════════════════════════════════'
                        echo ''
                        
                        if (criticalCount > 0) {
                            echo "⚠️  ATTENTION: ${criticalCount} vulnérabilités CRITICAL détectées!"
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