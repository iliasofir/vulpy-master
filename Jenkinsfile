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
                    
                    // Générer tous les rapports avec une seule commande Bandit
                    sh """
                        docker run --rm \
                        -v "${WORKSPACE}:/app" \
                        -w /app \
                        python:3.11-slim \
                        bash -c '
                            set -x
                            pip install bandit -q
                            echo "=== Current directory ==="
                            pwd
                            ls -la
                            echo "=== Creating reports directory ==="
                            mkdir -p /app/${REPORT_DIR}
                            ls -ld /app/${REPORT_DIR}
                            echo "=== Running Bandit ==="
                            bandit -r bad good utils -f html -o /app/${REPORT_DIR}/bandit-report.html || true
                            bandit -r bad good utils -f json -o /app/${REPORT_DIR}/bandit-report.json || true
                            bandit -r bad good utils -f txt -o /app/${REPORT_DIR}/bandit-report.txt || true
                            bandit -r bad good utils -f csv -o /app/${REPORT_DIR}/bandit-report.csv || true
                            echo "=== Files created ==="
                            ls -la /app/${REPORT_DIR}/
                            echo "=== Setting permissions ==="
                            chmod -R 777 /app/${REPORT_DIR}
                            echo "=== Final check ==="
                            ls -la /app/${REPORT_DIR}/
                        '
                    """
                    
                    // Vérification détaillée
                    sh """
                        echo "=== Vérification Jenkins - PWD ==="
                        pwd
                        echo "=== Contenu workspace ==="
                        ls -la
                        echo "=== Contenu ${REPORT_DIR} ==="
                        ls -la ${REPORT_DIR}/ || echo "Répertoire vide ou inexistant"
                        echo "=== Recherche fichiers bandit ==="
                        find . -name "bandit-*" -type f 2>/dev/null || echo "Aucun fichier trouvé"
                        echo "=== Permissions ${REPORT_DIR} ==="
                        ls -ld ${REPORT_DIR}/
                    """
                    
                    // Test de création d'un fichier simple
                    sh """
                        echo "=== Test d'écriture direct ==="
                        echo "test" > ${REPORT_DIR}/test.txt
                        ls -la ${REPORT_DIR}/
                    """
                    
                    if (fileExists("${REPORT_DIR}/bandit-report.html")) {
                        echo '✓ Rapports générés avec succès'
                    } else {
                        echo '⚠️ Rapports non trouvés - Problème de persistance Docker!'
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