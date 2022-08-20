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
shellcheck shell/*
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