pipeline {
    agent {
        label 'build-base-stable'
    }

    options {
        skipDefaultCheckout true
    }

    stages {
        stage('Checkout') {
            steps {
                dir("${env.WORKSPACE}") {
                    checkout scm
                }
            }
        }

        stage('Build') {
            steps {
                dir("${env.WORKSPACE}") {
                    sh '''
                        #!/usr/bin/env bash
                        set -euo pipefail
                        make build
                    '''
                }
            }
        }

        stage('Test') {
            steps {
                dir("${env.WORKSPACE}") {
                    sh '''
                        #!/usr/bin/env bash
                        set -euo pipefail
                        if command -v go >/dev/null 2>&1; then
                            make toolshed-runtime-test
                        else
                            echo "Go is not installed on this Jenkins agent; running shell-runtime smoke checks only."
                            bash ./list.sh --runtime shell > /dev/null
                            bash ./update.sh --runtime shell --help > /dev/null
                            bash ./uninstall.sh --runtime shell --help > /dev/null
                        fi
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Jenkins validation for repo scripts completed.'
        }
    }
}
