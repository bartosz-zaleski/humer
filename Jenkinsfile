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
    }
}