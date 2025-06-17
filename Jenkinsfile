pipeline {
  agent any

  options {
    // don’t do the default checkout; we’ll do checkout scm ourselves
    skipDefaultCheckout()
  }

  environment {
    // SonarQube server name in Jenkins
    SONARQ       = 'SonarQube'
    // Credential ID for your GitHub PAT (used to push values.yaml)
    GITHUB_CREDS = 'github-creds'
  }

  stages {
    stage('Checkout') {
      steps {
        // This uses the branch (main) Multibranch discovered
        checkout scm
      }
    }

    stage('Build Frontend') {
      // run this stage inside the official Node container
      agent {
        docker {
          image 'node:18-alpine'
          args  '-u root'  // run as root so npm install can write node_modules
        }
      }
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
          agent { label 'jenkins' }
          steps {
            dir('src/backend1') {
              sh './gradlew clean build'
            }
          }
        }
        stage('service-2') {
          agent { label 'jenkins' }
          steps {
            dir('src/backend2') {
              sh './gradlew clean build'
            }
          }
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
      }
    }

    stage('Docker & Trivy') {
      steps {
        script {
          def tag = env.BUILD_NUMBER
          // Build images
          sh "docker build --no-cache -t \${DOCKERHUB_USR}/frontend:\${tag} src/frontend"
          sh "docker build --no-cache -t \${DOCKERHUB_USR}/service1:\${tag} src/backend1"
          sh "docker build --no-cache -t \${DOCKERHUB_USR}/service2:\${tag} src/backend2"
          // Scan images
          sh "trivy image \${DOCKERHUB_USR}/frontend:\${tag}  > trivy-frontend.txt"
          sh "trivy image \${DOCKERHUB_USR}/service1:\${tag}   > trivy-service1.txt"
          sh "trivy image \${DOCKERHUB_USR}/service2:\${tag}   > trivy-service2.txt"
        }
      }
    }

    stage('Push & Update GitOps') {
      steps {
        // Login & push Docker Hub images
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKERHUB_USR',
          passwordVariable: 'DOCKERHUB_PSW'
        )]) {
          sh 'echo $DOCKERHUB_PSW | docker login -u $DOCKERHUB_USR --password-stdin'
          sh "docker push \$DOCKERHUB_USR/frontend:\$BUILD_NUMBER"
          sh "docker push \$DOCKERHUB_USR/service1:\$BUILD_NUMBER"
          sh "docker push \$DOCKERHUB_USR/service2:\$BUILD_NUMBER"
        }

        // Update Helm values.yaml
        dir('gitops/helm-chart') {
          sh '''#!/bin/bash
            sed -i \
              -e "s@^\\(\\s*frontend:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              -e "s@^\\(\\s*service1:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              -e "s@^\\(\\s*service2:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              values.yaml
          '''
          // Commit & push with your GitHub PAT
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
        to:      'sathwik.shetty@kickdrumtech.com,manav.verma@kickdrumtech.com,yashnitin.thakre@kickdrumtech.com,akashkumar.verma@kickdrumtech.com',
        subject: "Build SUCCESS #${env.BUILD_NUMBER}",
        body:    "✅ Build #${env.BUILD_NUMBER} succeeded!\nConsole: ${env.BUILD_URL}",
        attachmentsPattern: 'trivy-*.txt'
      )
    }
  }
}
