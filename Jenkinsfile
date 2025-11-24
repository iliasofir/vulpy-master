pipeline {
    agent any
    
    environment {
        // Configuration
        PROJECT_NAME = 'vulpy'
        DOCKER_IMAGE = 'vulpy-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        REPORT_DIR = 'security-reports'
        
        // Docker Registry - À CONFIGURER selon votre environnement
        DOCKER_REGISTRY = 'your-registry.azurecr.io'
        DOCKER_CREDENTIALS_ID = 'docker-registry-credentials'
        
        // Security Thresholds
        MAX_CRITICAL_VULNS = '0'
        MAX_HIGH_VULNS = '5'
        FAIL_ON_CRITICAL = 'true'
    }
    
    stages {
        stage('📥 Checkout Code') {
            steps {
                echo '================================================'
                echo '📥 Récupération du code source Vulpy'
                echo '================================================'
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/master']],
                    userRemoteConfigs: [[url: 'https://github.com/fportantier/vulpy.git']]
                ])
            }
        }
        
        stage('🔧 Préparation Environnement') {
            steps {
                echo '================================================'
                echo '🔧 Préparation de l\'environnement'
                echo '================================================'
                script {
                    // Créer le répertoire pour les rapports
                    sh "mkdir -p ${REPORT_DIR}"
                    
                    // Vérifier que Docker est disponible
                    sh 'docker --version || echo "Docker not found!"'
                    
                    echo '✓ Environnement préparé'
                }
            }
        }
        
        stage('🔍 SAST - Bandit') {
            steps {
                echo '================================================'
                echo '🔍 Analyse statique du code avec Bandit'
                echo '================================================'
                script {
                    echo '→ Exécution de Bandit via Docker...'
                    
                    def banditStatus = sh(
                        script: """
                            docker run --rm \
                              -v "\${WORKSPACE}:/src" \
                              -w /src \
                              python:3.11-slim \
                              bash -c "pip install bandit && \
                                       bandit -r bad -f json -o ${REPORT_DIR}/bandit-report.json; \
                                       bandit -r bad -f html -o ${REPORT_DIR}/bandit-report.html; \
                                       bandit -r bad -f txt -o ${REPORT_DIR}/bandit-report.txt || true"
                        """,
                        returnStatus: true
                    )
                    
                    if (banditStatus != 0) {
                        echo '⚠️  Bandit a détecté des problèmes de sécurité'
                        unstable(message: 'Bandit found security issues')
                    }
                    
                    echo '✓ Analyse SAST Bandit terminée'
                }
            }
        }
        
        stage('💎 SCA - Trivy (Code Source)') {
            steps {
                echo '================================================'
                echo '💎 Scan SCA avec Trivy - Code Source'
                echo '================================================'
                script {
                    // 1. Scan de requirements.txt
                    echo '→ Scan de requirements.txt...'
                    sh """
                        docker run --rm \
                          -v "\${WORKSPACE}:/workspace" \
                          aquasec/trivy:latest \
                          fs --scanners vuln \
                          --format json \
                          --output /workspace/${REPORT_DIR}/trivy-requirements.json \
                          /workspace/requirements.txt || true
                    """
                    
                    // 2. Scan des dépendances Python
                    echo '→ Scan des dépendances Python...'
                    sh """
                        docker run --rm \
                          -v "\${WORKSPACE}:/workspace" \
                          aquasec/trivy:latest \
                          fs --scanners vuln \
                          --format json \
                          --dependency-tree \
                          --output /workspace/${REPORT_DIR}/trivy-dependencies.json \
                          /workspace || true
                    """
                    
                    // 3. Scan complet (vuln + misconfig + secrets)
                    echo '→ Scan des fichiers (vuln + misconfig + secrets)...'
                    sh """
                        docker run --rm \
                          -v "\${WORKSPACE}:/workspace" \
                          aquasec/trivy:latest \
                          fs --scanners vuln,misconfig,secret \
                          --format json \
                          --output /workspace/${REPORT_DIR}/trivy-source-full.json \
                          /workspace || true
                    """
                    
                    // 4. Génération SBOM
                    echo '→ Génération du SBOM...'
                    sh """
                        docker run --rm \
                          -v "\${WORKSPACE}:/workspace" \
                          aquasec/trivy:latest \
                          fs --format cyclonedx \
                          --output /workspace/${REPORT_DIR}/trivy-sbom.json \
                          /workspace || true
                    """
                    
                    // 5. Rapport SARIF
                    sh """
                        docker run --rm \
                          -v "\${WORKSPACE}:/workspace" \
                          aquasec/trivy:latest \
                          fs --scanners vuln,misconfig,secret,license \
                          --format sarif \
                          --output /workspace/${REPORT_DIR}/trivy-source.sarif \
                          /workspace || true
                    """
                    
                    // 6. Rapport HTML
                    sh """
                        docker run --rm \
                          -v "\${WORKSPACE}:/workspace" \
                          aquasec/trivy:latest \
                          fs --scanners vuln,misconfig,secret \
                          --format template --template "@contrib/html.tpl" \
                          --output /workspace/${REPORT_DIR}/trivy-source-report.html \
                          /workspace || true
                    """
                    
                    echo '✓ Scan SCA Trivy (code source) terminé'
                }
            }
        }
        
        stage('🐳 Build Image Docker') {
            steps {
                echo '================================================'
                echo '🐳 Construction de l\'image Docker'
                echo '================================================'
                script {
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    """
                    echo "✓ Image construite: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        
        stage('💎 SCA - Trivy (Image Docker)') {
            steps {
                echo '================================================'
                echo '💎 Scan SCA avec Trivy - Image Docker'
                echo '================================================'
                script {
                    // 1. Scan des vulnérabilités
                    echo '→ Scan des vulnérabilités de l\'image...'
                    sh """
                        docker run --rm \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -v "\${WORKSPACE}/${REPORT_DIR}:/output" \
                          aquasec/trivy:latest \
                          image --scanners vuln \
                          --format json \
                          --output /output/trivy-image-vuln.json \
                          ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                    """
                    
                    // 2. Scan des secrets
                    echo '→ Scan des secrets dans l\'image...'
                    sh """
                        docker run --rm \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -v "\${WORKSPACE}/${REPORT_DIR}:/output" \
                          aquasec/trivy:latest \
                          image --scanners secret \
                          --format json \
                          --output /output/trivy-image-secrets.json \
                          ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                    """
                    
                    // 3. Scan des misconfigurations
                    echo '→ Scan des misconfigurations...'
                    sh """
                        docker run --rm \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -v "\${WORKSPACE}/${REPORT_DIR}:/output" \
                          aquasec/trivy:latest \
                          image --scanners misconfig \
                          --format json \
                          --output /output/trivy-image-misconfig.json \
                          ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                    """
                    
                    // 4. Rapport SARIF
                    sh """
                        docker run --rm \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -v "\${WORKSPACE}/${REPORT_DIR}:/output" \
                          aquasec/trivy:latest \
                          image --scanners vuln,secret,misconfig \
                          --format sarif \
                          --output /output/trivy-image-full.sarif \
                          ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                    """
                    
                    // 5. Rapport HTML
                    sh """
                        docker run --rm \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          -v "\${WORKSPACE}/${REPORT_DIR}:/output" \
                          aquasec/trivy:latest \
                          image --scanners vuln,secret,misconfig \
                          --format template --template "@contrib/html.tpl" \
                          --output /output/trivy-image-report.html \
                          ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                    """
                    
                    // 6. Afficher résumé
                    echo '→ Résumé des vulnérabilités:'
                    sh """
                        docker run --rm \
                          -v /var/run/docker.sock:/var/run/docker.sock \
                          aquasec/trivy:latest \
                          image --scanners vuln \
                          --format table \
                          --severity HIGH,CRITICAL \
                          ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                    """
                    
                    echo '✓ Scan SCA Trivy (image Docker) terminé'
                }
            }
        }
        
        stage('🛡️ Vérification Seuils Sécurité') {
            steps {
                echo '================================================'
                echo '🛡️ Vérification des seuils de sécurité'
                echo '================================================'
                script {
                    def reportFile = "${WORKSPACE}/${REPORT_DIR}/trivy-image-vuln.json"
                    
                    if (fileExists(reportFile)) {
                        def jsonReport = readJSON file: reportFile
                        def criticalCount = 0
                        def highCount = 0
                        
                        jsonReport.Results?.each { result ->
                            result.Vulnerabilities?.each { vuln ->
                                if (vuln.Severity == 'CRITICAL') {
                                    criticalCount++
                                } else if (vuln.Severity == 'HIGH') {
                                    highCount++
                                }
                            }
                        }
                        
                        echo "📊 Résumé des vulnérabilités:"
                        echo "   🔴 CRITICAL: ${criticalCount}"
                        echo "   🟠 HIGH: ${highCount}"
                        
                        if (env.FAIL_ON_CRITICAL == 'true' && criticalCount > env.MAX_CRITICAL_VULNS.toInteger()) {
                            error("❌ Build échoué: ${criticalCount} vulnérabilités CRITICAL détectées (seuil: ${env.MAX_CRITICAL_VULNS})")
                        }
                        
                        if (highCount > env.MAX_HIGH_VULNS.toInteger()) {
                            unstable(message: "⚠️ ${highCount} vulnérabilités HIGH détectées (seuil: ${env.MAX_HIGH_VULNS})")
                        }
                        
                        echo '✓ Vérification des seuils terminée'
                    } else {
                        echo '⚠️ Rapport Trivy non trouvé, impossible de vérifier les seuils'
                    }
                }
            }
        }
        
        stage('☁️ Push Docker Image') {
            when {
                expression { 
                    currentBuild.result == null || currentBuild.result == 'SUCCESS' 
                }
            }
            steps {
                echo '================================================'
                echo '☁️ Push de l\'image Docker vers le registry'
                echo '================================================'
                script {
                    try {
                        withCredentials([usernamePassword(
                            credentialsId: "${DOCKER_CREDENTIALS_ID}",
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )]) {
                            sh """
                                echo \$DOCKER_PASS | docker login ${DOCKER_REGISTRY} -u \$DOCKER_USER --password-stdin
                                docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                                docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest
                                docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                                docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:latest
                                docker logout ${DOCKER_REGISTRY}
                            """
                            echo "✓ Image poussée vers ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}"
                        }
                    } catch (Exception e) {
                        echo "⚠️ Erreur lors du push: ${e.message}"
                        echo "Vérifiez que les credentials '${DOCKER_CREDENTIALS_ID}' sont configurés dans Jenkins"
                        throw e
                    }
                }
            }
        }
        
        stage('📊 Archiver les Rapports') {
            steps {
                echo '================================================'
                echo '📊 Archivage des rapports de sécurité'
                echo '================================================'
                script {
                    archiveArtifacts artifacts: "${REPORT_DIR}/**/*", 
                                   allowEmptyArchive: false,
                                   fingerprint: true
                    
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: "${REPORT_DIR}",
                        reportFiles: 'bandit-report.html,trivy-source-report.html,trivy-image-report.html',
                        reportName: 'Security Reports',
                        reportTitles: 'Bandit SAST, Trivy SCA Source, Trivy SCA Image'
                    ])
                    
                    echo '✓ Rapports archivés avec succès'
                }
            }
        }
    }
    
    post {
        success {
            echo '###############################################'
            echo '#                                             #'
            echo '#   ✓ Pipeline terminé avec succès!           #'
            echo '#                                             #'
            echo '###############################################'
            echo ''
            echo "Image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "Rapports disponibles dans: ${REPORT_DIR}/"
        }
        unstable {
            echo '###############################################'
            echo '#                                             #'
            echo '#   ⚠️  Pipeline instable (warnings)          #'
            echo '#                                             #'
            echo '###############################################'
        }
        failure {
            echo '###############################################'
            echo '#                                             #'
            echo '#   ✗ Pipeline échoué!                        #'
            echo '#                                             #'
            echo '###############################################'
            echo ''
            echo 'Consultez les rapports de sécurité pour plus de détails'
        }
        always {
            echo 'Nettoyage des ressources...'
            script {
                try {
                    sh "docker image prune -f"
                } catch (Exception e) {
                    echo "⚠️ Erreur lors du nettoyage: ${e.message}"
                }
            }
        }
    }
}