pipeline {
  agent any

  environment {
    DOCKERHUB = credentials('dockerhub-creds')   // id of your Docker Hub creds in Jenkins
    GIT_SSH   = 'git-ssh'                         // id of your SSH key for GitOps repo
    SONARQ    = 'SonarQube'                       // name of your SonarQube server in Jenkins config
  }

  stages {
    stage('Cleanup') {
      steps { deleteDir() }
    }

    stage('Checkout') {
      steps {
        git url: 'git@github.com:AkashKickdrum/akash-argocd.git',
            credentialsId: GIT_SSH
      }
    }

    stage('Build Backends') {
      parallel {
        stage('service-1') {
          steps {
            dir('src/backend1') {
              sh './gradlew clean build'
            }
          }
        }
        stage('service-2') {
          steps {
            dir('src/backend2') {
              sh './gradlew clean build'
            }
          }
        }
      }
    }

    stage('Static Code Analysis') {
      steps {
        withSonarQubeEnv(SONARQ) {
          sh 'sonar-scanner -Dsonar.projectKey=backend1 -Dsonar.sources=src/backend1'
          sh 'sonar-scanner -Dsonar.projectKey=backend2 -Dsonar.sources=src/backend2'
        }
      }
    }

    stage('OWASP Dependency-Check') {
      steps {
        sh 'dependency-check.sh --project service1 --scan src/backend1'
        sh 'dependency-check.sh --project service2 --scan src/backend2'
      }
    }

    stage('Unit Tests') {
      steps {
        dir('src/backend1') { sh './gradlew test' }
        dir('src/backend2') { sh './gradlew test' }
      }
    }

    stage('Docker Build & Tag') {
      steps {
        script {
          def tag = "${env.BUILD_NUMBER}"
          sh "docker build --no-cache -t ${DOCKERHUB_USR}/frontend:${tag} src/frontend"
          sh "docker build --no-cache -t ${DOCKERHUB_USR}/service1:${tag} src/backend1"
          sh "docker build --no-cache -t ${DOCKERHUB_USR}/service2:${tag} src/backend2"
        }
      }
    }

    stage('Trivy Scan') {
      steps {
        sh "trivy image ${DOCKERHUB_USR}/frontend:${BUILD_NUMBER} > trivy-frontend.txt"
        sh "trivy image ${DOCKERHUB_USR}/service1:${BUILD_NUMBER} > trivy-service1.txt"
        sh "trivy image ${DOCKERHUB_USR}/service2:${BUILD_NUMBER} > trivy-service2.txt"
      }
    }

    stage('Push & Cleanup Images') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                          usernameVariable: 'USER',
                                          passwordVariable: 'PASS')]) {
          sh 'echo $PASS | docker login -u $USER --password-stdin'
          sh "docker push ${DOCKERHUB_USR}/frontend:${BUILD_NUMBER}"
          sh "docker push ${DOCKERHUB_USR}/service1:${BUILD_NUMBER}"
          sh "docker push ${DOCKERHUB_USR}/service2:${BUILD_NUMBER}"
          sh "docker image rm ${DOCKERHUB_USR}/frontend:${BUILD_NUMBER}"
          sh "docker image rm ${DOCKERHUB_USR}/service1:${BUILD_NUMBER}"
          sh "docker image rm ${DOCKERHUB_USR}/service2:${BUILD_NUMBER}"
        }
      }
    }

    stage('Update GitOps Manifests') {
      steps {
        dir('gitops/helm-chart') {
          sh """\
            sed -i "s/^ *tag:.*/  tag: \\"${BUILD_NUMBER}\\"/" values.yaml
          """
        }
        sshagent([GIT_SSH]) {
          sh """
            git add gitops/helm-chart/values.yaml
            git commit -m "ci: bump image tag to ${BUILD_NUMBER}"
            git push origin main
          """
        }
      }
    }

    stage('Notify') {
      steps {
        emailext(
          to:      'sathwik.shetty@kickdrumtech.com,manav.verma@kickdrumtech.com,yashnitin.thakre@kickdrumtech.com',
          cc:      'akashkumar.verma@kickdrumtech.com',
          subject: "Build #${BUILD_NUMBER} Report",
          body:    "Please find attached the Trivy vulnerability scans.",
          attachmentsPattern: 'trivy-*.txt'
        )
      }
    }
  }

  post {
    failure {
      emailext subject: "Build FAILED #${BUILD_NUMBER}", body: "Check console output", to: 'akashkumar.verma@kickdrumtech.com'
    }
  }
}
