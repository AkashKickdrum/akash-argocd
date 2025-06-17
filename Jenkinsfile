pipeline {
  agent any

  environment {
    // binding your Docker Hub creds to DOCKERHUB_USR / DOCKERHUB_PSW
    DOCKERHUB_USR = credentials('dockerhub-creds_USR')
    DOCKERHUB_PSW = credentials('dockerhub-creds_PSW')

    // SonarQube server ID in Jenkins
    SONARQ = 'SonarQube'
  }

  stages {
    stage('Cleanup') {
      steps { deleteDir() }
    }

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Frontend') {
      steps {
        dir('src/frontend') {
          sh 'npm install'
          sh 'npm run build'
        }
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
          sh 'sonar-scanner -Dsonar.projectKey=service1 -Dsonar.sources=src/backend1'
          sh 'sonar-scanner -Dsonar.projectKey=service2 -Dsonar.sources=src/backend2'
        }
      }
    }

    stage('Security Scans & Tests') {
      parallel {
        stage('OWASP & Unit Tests') {
          steps {
            sh 'dependency-check.sh --project service1 --scan src/backend1'
            sh 'dependency-check.sh --project service2 --scan src/backend2'
            dir('src/backend1') { sh './gradlew test' }
            dir('src/backend2') { sh './gradlew test' }
          }
        }
        stage('Trivy Scans') {
          steps {
            script {
              def tag = env.BUILD_NUMBER
              sh "docker build --no-cache -t myhub/frontend:${tag} src/frontend"
              sh "docker build --no-cache -t myhub/service1:${tag} src/backend1"
              sh "docker build --no-cache -t myhub/service2:${tag} src/backend2"
              sh "trivy image myhub/frontend:${tag} > trivy-frontend.txt"
              sh "trivy image myhub/service1:${tag}  > trivy-service1.txt"
              sh "trivy image myhub/service2:${tag}  > trivy-service2.txt"
            }
          }
        }
      }
    }

    stage('Push Images & Update GitOps') {
      steps {
        sh 'echo $DOCKERHUB_PSW | docker login -u $DOCKERHUB_USR --password-stdin'
        sh 'docker push myhub/frontend:${BUILD_NUMBER}'
        sh 'docker push myhub/service1:${BUILD_NUMBER}'
        sh 'docker push myhub/service2:${BUILD_NUMBER}'

        dir('gitops/helm-chart') {
          sh '''#!/bin/bash
            sed -i \
              -e "s@^\\(\\s*frontend:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              -e "s@^\\(\\s*service1:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              -e "s@^\\(\\s*service2:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              values.yaml
          '''
        }

        sshagent(['git-ssh']) {
          sh '''
            git add values.yaml
            git commit -m "ci: bump image tags to ${BUILD_NUMBER}"
            git push origin main
          '''
        }
      }
    }

    stage('Notify') {
      steps {
        emailext(
          to: 'sathwik.shetty@kickdrumtech.com,manav.verma@kickdrumtech.com,yashnitin.thakre@kickdrumtech.com,akashkumar.verma@kickdrumtech.com',
          subject: "Build #${BUILD_NUMBER} ${currentBuild.currentResult}",
          body: "Console: ${env.BUILD_URL}",
          attachmentsPattern: 'trivy-*.txt'
        )
      }
    }
  }

  post {
    always { archiveArtifacts artifacts: 'trivy-*.txt' }
  }
}
