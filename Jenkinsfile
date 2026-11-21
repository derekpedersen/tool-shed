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
                        make test
                        make toolshed-runtime-test
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
