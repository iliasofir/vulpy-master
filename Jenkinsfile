pipeline {
    agent any
    
    environment {
        PYTHON_VERSION = '3.9'
        VIRTUAL_ENV = '.venv'
        DOCKER_IMAGE_NAME = 'vulpy'
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
        TRIVY_VERSION = 'latest'
    }

    stages {
        stage('Setup Environment') {
            steps {
                echo '🔧 Setting up Python environment...'
                sh '''
                    python3 -m venv ${VIRTUAL_ENV}
                    . ${VIRTUAL_ENV}/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }
        
        stage('SAST - Bandit (Static Code Analysis)') {
            steps {
                echo '🔍 Running Bandit - Static Application Security Testing...'
                sh '''
                    . ${VIRTUAL_ENV}/bin/activate
                    pip install bandit
                    
                    # Create reports directory
                    mkdir -p reports
                    
                    # Scan Python files for security issues
                    echo "=== Bandit Security Scan ===" | tee reports/bandit-summary.txt
                    bandit -r bad/ good/ utils/ -f json -o reports/bandit-report.json || true
                    bandit -r bad/ good/ utils/ -f txt -o reports/bandit-report.txt || true
                    bandit -r bad/ good/ utils/ -f html -o reports/bandit-report.html || true
                    
                    # Display summary
                    bandit -r bad/ good/ utils/ --severity-level medium || true
                    
                    echo "✅ Bandit scan completed - Reports saved in reports/"
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/bandit-*', allowEmptyArchive: true
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'reports',
                        reportFiles: 'bandit-report.html',
                        reportName: 'Bandit Security Report'
                    ])
                }
            }
        }
        
        stage('SCA - Scan Dependencies') {
            parallel {
                stage('Scan requirements.txt') {
                    steps {
                        echo '📋 Scanning requirements.txt...'
                        sh '''
                            . ${VIRTUAL_ENV}/bin/activate
                            pip install safety pip-audit
                            
                            mkdir -p reports
                            
                            # Safety scan
                            safety check --file requirements.txt --json > reports/safety-requirements.json || true
                            safety check --file requirements.txt | tee reports/safety-requirements.txt || true
                            
                            # pip-audit scan
                            pip-audit -r requirements.txt --format json > reports/pip-audit-requirements.json || true
                            pip-audit -r requirements.txt | tee reports/pip-audit-requirements.txt || true
                        '''
                    }
                }
                
                stage('Scan Python Dependencies') {
                    steps {
                        echo '🐍 Scanning all Python dependencies...'
                        sh '''
                            . ${VIRTUAL_ENV}/bin/activate
                            
                            mkdir -p reports
                            
                            # Full dependency scan
                            pip-audit --desc --format json > reports/pip-audit-full.json || true
                            pip-audit --desc | tee reports/pip-audit-full.txt || true
                        '''
                    }
                }
                
                stage('Scan Transitive Dependencies') {
                    steps {
                        echo '🔗 Analyzing transitive dependencies...'
                        sh '''
                            . ${VIRTUAL_ENV}/bin/activate
                            pip install pipdeptree
                            
                            mkdir -p reports
                            
                            # Generate dependency tree
                            pipdeptree --json > reports/dependencies-tree.json
                            pipdeptree --graph-output png > reports/dependencies-graph.png || true
                            pipdeptree | tee reports/dependencies-tree.txt
                            
                            # Full freeze for scanning
                            pip freeze > reports/all-dependencies.txt
                            
                            # Scan all including transitive
                            safety check --json > reports/safety-full.json || true
                            safety check | tee reports/safety-full.txt || true
                        '''
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/safety-*,reports/pip-audit-*,reports/dependencies-*,reports/all-dependencies.txt', allowEmptyArchive: true
                }
            }
        }
        
        stage('Supply Chain Analysis') {
            steps {
                echo '🔐 Performing supply chain security analysis...'
                sh '''
                    . ${VIRTUAL_ENV}/bin/activate
                    
                    mkdir -p reports
                    
                    # Generate SBOM (Software Bill of Materials)
                    pip install cyclonedx-bom
                    cyclonedx-py -r -i requirements.txt -o reports/sbom.json --format json
                    cyclonedx-py -r -i requirements.txt -o reports/sbom.xml --format xml
                    
                    # License compliance check
                    pip install pip-licenses
                    pip-licenses --format=json > reports/licenses.json
                    pip-licenses --format=csv > reports/licenses.csv
                    pip-licenses --format=markdown > reports/licenses.md
                    pip-licenses | tee reports/licenses.txt
                    
                    # Check for malicious packages (optional - requires guarddog)
                    pip install guarddog 2>/dev/null || echo "GuardDog not available"
                    guarddog pypi scan requirements.txt > reports/guarddog-scan.txt 2>&1 || true
                    
                    echo "✅ Supply chain analysis completed"
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/sbom.*,reports/licenses.*,reports/guarddog-*', allowEmptyArchive: true
                }
            }
        }
        
        stage('Verify Trivy Installation') {
            steps {
                echo '🐳 Verifying Trivy installation...'
                sh '''
                    if ! command -v trivy &> /dev/null; then
                        echo "⚠️  Trivy not found. Installing Trivy..."
                        
                        # Install Trivy (for macOS/Linux)
                        if [[ "$OSTYPE" == "darwin"* ]]; then
                            brew install aquasecurity/trivy/trivy
                        else
                            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
                            sudo apt-get update
                            sudo apt-get install trivy
                        fi
                    fi
                    
                    trivy --version
                    echo "✅ Trivy is ready"
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh '''
                    # Build the Docker image
                    docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                    docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest
                    
                    echo "✅ Docker image built: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                '''
            }
        }
        
        stage('SCA - Trivy (Scan Docker Image)') {
            steps {
                echo '🔍 Scanning Docker image with Trivy...'
                sh '''
                    mkdir -p reports
                    
                    # Scan Docker image for vulnerabilities
                    echo "=== Trivy Image Scan ===" | tee reports/trivy-summary.txt
                    
                    # JSON report
                    trivy image --format json --output reports/trivy-image-report.json ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || true
                    
                    # HTML report
                    trivy image --format template --template "@contrib/html.tpl" --output reports/trivy-image-report.html ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || true
                    
                    # Table format for console
                    trivy image --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} | tee reports/trivy-image-report.txt || true
                    
                    # Scan for misconfigurations
                    trivy image --scanners config --format json --output reports/trivy-config-report.json ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || true
                    
                    # Scan for secrets
                    trivy image --scanners secret --format json --output reports/trivy-secrets-report.json ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || true
                    
                    echo "✅ Trivy scan completed"
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/trivy-*', allowEmptyArchive: true
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'reports',
                        reportFiles: 'trivy-image-report.html',
                        reportName: 'Trivy Image Scan Report'
                    ])
                }
            }
        }
        
        stage('Generate Consolidated Report') {
            steps {
                echo '📊 Generating consolidated security report...'
                sh '''
                    mkdir -p reports
                    
                    cat > reports/security-summary.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Security Scan Summary - Vulpy</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; }
        .scan-box { background: #ecf0f1; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #3498db; }
        .success { border-left-color: #27ae60; }
        .warning { border-left-color: #f39c12; }
        .danger { border-left-color: #e74c3c; }
        .timestamp { color: #7f8c8d; font-size: 0.9em; }
        ul { line-height: 1.8; }
        .report-link { display: inline-block; margin: 5px; padding: 8px 15px; background: #3498db; color: white; text-decoration: none; border-radius: 4px; }
        .report-link:hover { background: #2980b9; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Security Scan Summary Report</h1>
        <p class="timestamp">Generated: $(date)</p>
        <p class="timestamp">Project: <strong>Vulpy</strong></p>
        <p class="timestamp">Build: <strong>#${BUILD_NUMBER}</strong></p>
        
        <h2>📋 Scans Performed</h2>
        
        <div class="scan-box danger">
            <h3>1. 🔍 SAST - Bandit (Static Code Analysis)</h3>
            <p>Static analysis of Python source code for security vulnerabilities</p>
            <ul>
                <li>Scanned directories: bad/, good/, utils/</li>
                <li>Detection of hardcoded secrets, SQL injection, XSS vulnerabilities</li>
                <li>Security best practices validation</li>
            </ul>
            <a href="bandit-report.html" class="report-link">View Bandit Report</a>
        </div>
        
        <div class="scan-box warning">
            <h3>2. 📦 SCA - Dependency Scanning</h3>
            <p>Analysis of Python dependencies for known vulnerabilities</p>
            <ul>
                <li>✅ requirements.txt scan (Safety + pip-audit)</li>
                <li>✅ All Python dependencies scan</li>
                <li>✅ Transitive dependencies analysis (pipdeptree)</li>
            </ul>
        </div>
        
        <div class="scan-box success">
            <h3>3. 🔗 Supply Chain Analysis</h3>
            <p>Comprehensive supply chain security assessment</p>
            <ul>
                <li>✅ SBOM generation (CycloneDX format)</li>
                <li>✅ License compliance check</li>
                <li>✅ Malicious package detection (GuardDog)</li>
            </ul>
        </div>
        
        <div class="scan-box warning">
            <h3>4. 🐳 SCA - Trivy (Container Scan)</h3>
            <p>Docker image vulnerability and misconfiguration scanning</p>
            <ul>
                <li>✅ Vulnerability scan (OS packages + app dependencies)</li>
                <li>✅ Misconfiguration detection</li>
                <li>✅ Secret detection in image layers</li>
            </ul>
            <a href="trivy-image-report.html" class="report-link">View Trivy Report</a>
        </div>
        
        <h2>📊 Generated Reports</h2>
        <ul>
            <li><strong>Bandit:</strong> bandit-report.json, bandit-report.txt, bandit-report.html</li>
            <li><strong>Safety:</strong> safety-requirements.json, safety-full.json</li>
            <li><strong>pip-audit:</strong> pip-audit-requirements.json, pip-audit-full.json</li>
            <li><strong>Dependencies:</strong> dependencies-tree.json, all-dependencies.txt</li>
            <li><strong>SBOM:</strong> sbom.json, sbom.xml</li>
            <li><strong>Licenses:</strong> licenses.json, licenses.csv, licenses.md</li>
            <li><strong>Trivy:</strong> trivy-image-report.json, trivy-image-report.html</li>
        </ul>
        
        <h2>🎯 Next Steps</h2>
        <ol>
            <li>Review Bandit report for high-severity code vulnerabilities</li>
            <li>Check dependency reports for CVEs and update vulnerable packages</li>
            <li>Review Trivy report for container vulnerabilities</li>
            <li>Verify license compliance</li>
            <li>Remediate identified security issues</li>
        </ol>
        
        <p style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #7f8c8d;">
            All reports are archived and available in the Jenkins build artifacts.
        </p>
    </div>
</body>
</html>
EOF
                    
                    echo "✅ Consolidated report generated"
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/security-summary.html', allowEmptyArchive: true
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'reports',
                        reportFiles: 'security-summary.html',
                        reportName: 'Security Summary Report'
                    ])
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            sh '''
                # Archive all reports
                tar -czf security-reports-${BUILD_NUMBER}.tar.gz reports/ 2>/dev/null || true
            '''
            archiveArtifacts artifacts: 'security-reports-*.tar.gz', allowEmptyArchive: true
        }
        success {
            echo '✅ Security scans completed successfully!'
            emailext (
                subject: "✅ Security Scan SUCCESS: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: """
                Security scans completed successfully for Vulpy project.
                
                Scans performed:
                - SAST with Bandit
                - SCA for dependencies (requirements.txt, Python packages, transitive deps)
                - Supply chain analysis (SBOM, licenses)
                - Container scan with Trivy
                
                Please review the archived reports in Jenkins.
                
                Build URL: ${env.BUILD_URL}
                """,
                to: '${DEFAULT_RECIPIENTS}',
                attachLog: false,
                mimeType: 'text/plain'
            )
        }
        failure {
            echo '❌ Security scans encountered issues!'
            emailext (
                subject: "❌ Security Scan FAILURE: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: """
                Security scans failed for Vulpy project.
                
                Please check the console output for details.
                
                Build URL: ${env.BUILD_URL}
                Console: ${env.BUILD_URL}console
                """,
                to: '${DEFAULT_RECIPIENTS}',
                attachLog: true,
                mimeType: 'text/plain'
            )
        }
    }
}
