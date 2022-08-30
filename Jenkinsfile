pipeline {
    agent {
        label "ubuntu"
    }
    stages {
        stage('shellcheck') {
            agent {
                label "shellcheck"
            }
            steps {
                sh '''
shellcheck -x shell/*
shellcheck -x device/*
                '''   
            }
        }
        stage('bats') {
            agent {
                label "bats"
            }
            steps {
                dir('test/') {
                    sh '''
bats listener.sh
                    '''
                }
            }
        }
    }
}