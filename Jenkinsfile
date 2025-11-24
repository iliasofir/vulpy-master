pipeline {
    agent any

    stages {
        stage('SAST - Bandit (Static Code Analysis)') {
            steps {
                echo '🔍 Running Bandit via Docker...'
                sh '''
                    # Create reports directory
                    mkdir -p reports
                    
                    # Run Bandit in Docker container
                    docker run --rm \
                      -v $(pwd):/src \
                      -w /src \
                      python:3.9-slim \
                      bash -c "
                        pip install bandit && \
                        echo '=== Bandit Security Scan ===' && \
                        echo 'Scanning directories: bad/, good/, utils/' && \
                        bandit -r bad/ good/ utils/ -f json -o reports/bandit-report.json || true && \
                        bandit -r bad/ good/ utils/ -f txt -o reports/bandit-report.txt || true && \
                        bandit -r bad/ good/ utils/ -f html -o reports/bandit-report.html || true && \
                        bandit -r bad/ good/ utils/ -f csv -o reports/bandit-report.csv || true && \
                        echo '' && \
                        echo '=== Bandit Scan Results ===' && \
                        bandit -r bad/ good/ utils/ --severity-level medium || true && \
                        echo '' && \
                        echo '✅ Bandit scan completed'
                      "
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
        
        stage('Generate Summary Report') {
            steps {
                echo '📊 Generating Bandit summary report...'
                sh '''
                    mkdir -p reports
                    
                    cat > reports/bandit-summary.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Bandit Security Scan - Vulpy</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0;
            padding: 20px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { 
            max-width: 1000px; 
            margin: 0 auto; 
            background: white; 
            padding: 40px; 
            border-radius: 15px; 
            box-shadow: 0 10px 40px rgba(0,0,0,0.2); 
        }
        h1 { 
            color: #2c3e50; 
            border-bottom: 4px solid #e74c3c; 
            padding-bottom: 15px;
            margin-top: 0;
        }
        h2 { 
            color: #34495e; 
            margin-top: 30px;
            border-left: 4px solid #3498db;
            padding-left: 15px;
        }
        .header-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .header-box h1 {
            color: white;
            border: none;
            margin: 0;
            padding: 0;
        }
        .info-box { 
            background: #ecf0f1; 
            padding: 20px; 
            margin: 15px 0; 
            border-radius: 8px; 
            border-left: 5px solid #3498db; 
        }
        .warning-box {
            background: #fff3cd;
            border-left-color: #ffc107;
        }
        .danger-box {
            background: #f8d7da;
            border-left-color: #dc3545;
        }
        .success-box {
            background: #d4edda;
            border-left-color: #28a745;
        }
        .timestamp { 
            color: #7f8c8d; 
            font-size: 0.95em;
            margin: 5px 0;
        }
        ul { 
            line-height: 2;
            padding-left: 20px;
        }
        li {
            margin: 8px 0;
        }
        .report-link { 
            display: inline-block; 
            margin: 10px 10px 10px 0; 
            padding: 12px 25px; 
            background: #e74c3c; 
            color: white; 
            text-decoration: none; 
            border-radius: 6px;
            font-weight: bold;
            transition: background 0.3s;
        }
        .report-link:hover { 
            background: #c0392b;
            transform: translateY(-2px);
        }
        .vulnerability-types {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .vuln-card {
            background: white;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            padding: 15px;
            transition: transform 0.2s;
        }
        .vuln-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .vuln-card h4 {
            margin-top: 0;
            color: #e74c3c;
        }
        .badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
            margin-right: 10px;
        }
        .badge-high { background: #dc3545; color: white; }
        .badge-medium { background: #ffc107; color: #000; }
        .badge-low { background: #28a745; color: white; }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #ddd;
            color: #7f8c8d;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header-box">
            <h1>🔒 Bandit Security Scan Report</h1>
            <p class="timestamp" style="color: white; margin: 10px 0 0 0;">Static Application Security Testing (SAST) for Python Code</p>
        </div>
        
        <div class="info-box">
            <p class="timestamp"><strong>Project:</strong> Vulpy (Vulnerable Python Application)</p>
            <p class="timestamp"><strong>Build Number:</strong> #${BUILD_NUMBER}</p>
            <p class="timestamp"><strong>Scan Date:</strong> $(date)</p>
            <p class="timestamp"><strong>Tool:</strong> Bandit v$(. ${VIRTUAL_ENV}/bin/activate && bandit --version | head -n1)</p>
        </div>
        
        <h2>📋 Scan Overview</h2>
        <div class="info-box danger-box">
            <h3>🎯 Scanned Directories</h3>
            <ul>
                <li><strong>bad/</strong> - Intentionally vulnerable code examples</li>
                <li><strong>good/</strong> - Secure code implementations</li>
                <li><strong>utils/</strong> - Utility functions</li>
            </ul>
        </div>
        
        <h2>🔍 Vulnerability Types Detected by Bandit</h2>
        <div class="vulnerability-types">
            <div class="vuln-card">
                <h4>🗄️ SQL Injection</h4>
                <p>Detects unsafe SQL query construction that could lead to SQL injection attacks.</p>
            </div>
            <div class="vuln-card">
                <h4>🔑 Hardcoded Secrets</h4>
                <p>Identifies passwords, API keys, and tokens hardcoded in source code.</p>
            </div>
            <div class="vuln-card">
                <h4>⚡ Command Injection</h4>
                <p>Finds unsafe execution of shell commands with user input.</p>
            </div>
            <div class="vuln-card">
                <h4>🌐 XSS Vulnerabilities</h4>
                <p>Detects potential Cross-Site Scripting issues in templates.</p>
            </div>
            <div class="vuln-card">
                <h4>🔐 Weak Cryptography</h4>
                <p>Identifies use of weak or deprecated cryptographic methods.</p>
            </div>
            <div class="vuln-card">
                <h4>📝 YAML Deserialization</h4>
                <p>Detects unsafe YAML parsing that could lead to code execution.</p>
            </div>
        </div>
        
        <h2>📊 Generated Reports</h2>
        <div class="info-box success-box">
            <p><strong>Multiple formats available:</strong></p>
            <ul>
                <li>📄 <strong>JSON:</strong> bandit-report.json (machine-readable)</li>
                <li>📝 <strong>Text:</strong> bandit-report.txt (console output)</li>
                <li>🌐 <strong>HTML:</strong> bandit-report.html (visual report)</li>
                <li>📊 <strong>CSV:</strong> bandit-report.csv (spreadsheet format)</li>
            </ul>
            <div style="margin-top: 20px;">
                <a href="bandit-report.html" class="report-link">📄 View Detailed HTML Report</a>
            </div>
        </div>
        
        <h2>🎯 Severity Levels</h2>
        <div class="info-box">
            <p><span class="badge badge-high">HIGH</span> Critical vulnerabilities requiring immediate attention</p>
            <p><span class="badge badge-medium">MEDIUM</span> Important issues that should be addressed</p>
            <p><span class="badge badge-low">LOW</span> Minor issues and best practice violations</p>
        </div>
        
        <h2>🔄 Next Steps</h2>
        <div class="info-box warning-box">
            <ol>
                <li><strong>Review the detailed HTML report</strong> for all findings</li>
                <li><strong>Prioritize HIGH severity issues</strong> for immediate remediation</li>
                <li><strong>Compare bad/ vs good/</strong> directories to understand secure coding practices</li>
                <li><strong>Update vulnerable code</strong> following security best practices</li>
                <li><strong>Re-run the scan</strong> after fixes to verify improvements</li>
            </ol>
        </div>
        
        <h2>📚 Resources</h2>
        <div class="info-box">
            <ul>
                <li>🔗 <a href="https://bandit.readthedocs.io/" target="_blank">Bandit Documentation</a></li>
                <li>🔗 <a href="https://owasp.org/www-project-top-ten/" target="_blank">OWASP Top 10</a></li>
                <li>🔗 <a href="https://cwe.mitre.org/" target="_blank">CWE Database</a></li>
            </ul>
        </div>
        
        <div class="footer">
            <p>🔒 Security Scan powered by Bandit | Jenkins Build #${BUILD_NUMBER}</p>
            <p>All reports are archived in Jenkins artifacts</p>
        </div>
    </div>
</body>
</html>
EOF
                    
                    echo "✅ Summary report generated"
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'reports',
                        reportFiles: 'bandit-summary.html',
                        reportName: 'Bandit Summary'
                    ])
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Archiving Bandit reports...'
            archiveArtifacts artifacts: 'reports/*', allowEmptyArchive: true
        }
        success {
            echo '✅ Bandit scan completed successfully!'
            echo '📊 Check the "Bandit Security Report" in the Jenkins UI'
        }
        failure {
            echo '❌ Bandit scan encountered issues!'
            echo '📋 Check the console output for error details'
        }
    }
}