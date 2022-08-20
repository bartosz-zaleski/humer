pipeline {
    agent {
        label: "ubuntu"
    }
    stages {
        stage('ubuntu') {
            agent {
                label: "shellcheck"
            }
            steps {
                sh '''
                pwd
                find .
                shellcheck --version
                '''   
            }
        }
    }
}