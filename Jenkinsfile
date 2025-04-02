pipeline {
    // any: trouve la cible plus facile: jenkins lui-même
    agent any

    stages {
        stage('Build Tomcat Image') {
            // on lance un conteneur contenant la cli docker
            // pour automatoser la construction de l'image
            agent {
                docker {
                    image 'docker:28.0.4-cli'
                    // on donne l'accès au conteneur docker-cli au serveur docker de la VM
                    // -u root: il n'ya de uid 1000 sur ce conteneur
                    args ' -u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh '''
                   cd stack-java/tomcat
                   docker build -t jenkins.lan:443/stack-java-tomcat:0.1 . --push
                   docker rmi jenkins.lan:443/stack-java-tomcat:0.1
                '''
            }
        }
    }
}