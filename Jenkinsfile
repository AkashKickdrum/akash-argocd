pipeline {
  agent any

  environment {
    // Docker Hub credentials: store your username/token in Jenkins as 'dockerhub-creds'
    DOCKERHUB_USR = credentials('dockerhub-creds_USR')
    DOCKERHUB_PSW = credentials('dockerhub-creds_PSW')

    // GitHub PAT credential for pushing back to GitOps repo
    GITHUB_CREDS = 'github-creds'  

    // SonarQube server configured in Jenkins
    SONARQ      = 'SonarQube'
  }

  stages {
    stage('Checkout') {
      steps {
        // HTTPS + PAT checkout
        git(
          url:      'https://github.com/AkashKickdrum/akash-argocd.git',
          credentialsId: GITHUB_CREDS
        )
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

    stage('Static Analysis') {
      steps {
        withSonarQubeEnv(SONARQ) {
          sh 'sonar-scanner -Dsonar.projectKey=service1 -Dsonar.sources=src/backend1'
          sh 'sonar-scanner -Dsonar.projectKey=service2 -Dsonar.sources=src/backend2'
        }
      }
    }

    stage('Security & Unit Tests') {
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

    stage('Docker Build & Trivy') {
      steps {
        script {
          def tag = env.BUILD_NUMBER
          // Build images
          sh "docker build --no-cache -t ${DOCKERHUB_USR}/frontend:${tag} src/frontend"
          sh "docker build --no-cache -t ${DOCKERHUB_USR}/service1:${tag} src/backend1"
          sh "docker build --no-cache -t ${DOCKERHUB_USR}/service2:${tag} src/backend2"
          // Vulnerability scan
          sh "trivy image ${DOCKERHUB_USR}/frontend:${tag}  > trivy-frontend.txt"
          sh "trivy image ${DOCKERHUB_USR}/service1:${tag}  > trivy-service1.txt"
          sh "trivy image ${DOCKERHUB_USR}/service2:${tag}  > trivy-service2.txt"
        }
      }
    }

    stage('Push & Update GitOps') {
      steps {
        script {
          sh 'echo $DOCKERHUB_PSW | docker login -u $DOCKERHUB_USR --password-stdin'
          sh "docker push ${DOCKERHUB_USR}/frontend:${BUILD_NUMBER}"
          sh "docker push ${DOCKERHUB_USR}/service1:${BUILD_NUMBER}"
          sh "docker push ${DOCKERHUB_USR}/service2:${BUILD_NUMBER}"
        }
        dir('gitops/helm-chart') {
          sh '''#!/bin/bash
            # Update all three tags in values.yaml
            sed -i \
              -e "s@^\\(\\s*frontend:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              -e "s@^\\(\\s*service1:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              -e "s@^\\(\\s*service2:\\).*@\\1 tag: \\"${BUILD_NUMBER}\\"@" \
              values.yaml
          '''
          // Commit & push via GitHub PAT
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
