pipeline {
  agent any

  // Prevent Declarative from doing an implicit checkout at the top
  options {
    skipDefaultCheckout()
  }

  environment {
    SONARQ     = 'SonarQube'
    GITHUB_CREDS = 'github-creds'
  }

  stages {
    stage('Checkout') {
      steps {
        // This will use the branch (main) that Multibranch discovered
        checkout scm
      }
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
          steps { dir('src/backend1') { sh './gradlew clean build' } }
        }
        stage('service-2') {
          steps { dir('src/backend2') { sh './gradlew clean build' } }
        }
      }
    }

    stage('Static Analysis') {
      steps {
        withSonarQubeEnv(SONARQ) {
          sh 'sonar-scanner -Dsonar.projectKey=service1 -Dsonar.sources=src/backend1'
          sh 'sonar-scanner -Dsonar.projectKey=service2 -Dsonar.sources=src/backend2'
        }
      }
    }

    stage('Security & Tests') {
      parallel {
        stage('Dependency-Check') {
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
      }
    }

    stage('Docker & Trivy') {
      steps {
        script {
          def tag = env.BUILD_NUMBER
          sh "docker build --no-cache -t myhub/frontend:${tag} src/frontend"
          sh "docker build --no-cache -t myhub/service1:${tag} src/backend1"
          sh "docker build --no-cache -t myhub/service2:${tag} src/backend2"
          sh "trivy image myhub/frontend:${tag}  > trivy-frontend.txt"
          sh "trivy image myhub/service1:${tag}  > trivy-service1.txt"
          sh "trivy image myhub/service2:${tag}  > trivy-service2.txt"
        }
      }
    }

    stage('Push & Update GitOps') {
      steps {
        // Docker Hub login & push
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKERHUB_USR',
          passwordVariable: 'DOCKERHUB_PSW'
        )]) {
          sh 'echo $DOCKERHUB_PSW | docker login -u $DOCKERHUB_USR --password-stdin'
          sh "docker push $DOCKERHUB_USR/frontend:${BUILD_NUMBER}"
          sh "docker push $DOCKERHUB_USR/service1:${BUILD_NUMBER}"
          sh "docker push $DOCKERHUB_USR/service2:${BUILD_NUMBER}"
        }

        dir('gitops/helm-chart') {
          sh '''#!/bin/bash
            sed -i \
              -e "s@^\\(\\s*frontend:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              -e "s@^\\(\\s*service1:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              -e "s@^\\(\\s*service2:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              values.yaml
          '''
          sshagent([GITHUB_CREDS]) {
            sh '''
              git add values.yaml
              git commit -m "ci: bump image tags to ${BUILD_NUMBER}"
              git push origin main
            '''
          }
        }
      }
    }
  }

  post {
    success {
      emailext(
        to: 'sathwik.shetty@kickdrumtech.com,manav.verma@kickdrumtech.com,yashnitin.thakre@kickdrumtech.com,akashkumar.verma@kickdrumtech.com',
        subject: "Build SUCCESS #${BUILD_NUMBER}",
        body:    "✅ Build #${BUILD_NUMBER} succeeded!\nConsole: ${BUILD_URL}",
        attachmentsPattern: 'trivy-*.txt'
      )
    }
  }
}
