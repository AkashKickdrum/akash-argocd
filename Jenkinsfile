pipeline {
  agent any

  options {
    skipDefaultCheckout()
  }

  environment {
    GITHUB_CREDS = 'github-creds'    // your GitHub PAT for pushing values.yaml
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Frontend') {
      steps {
        dir('src/frontend') {
          sh '''
            docker run --rm -u root \
              -v "$PWD":/app -w /app \
              node:18-alpine \
              sh -c "npm install && npm run build"
          '''
        }
      }
    }

    stage('Build Backends') {
      parallel {
        stage('service-1') {
          steps {
            dir('src/backend1') {
              sh 'chmod +x gradlew'
              sh './gradlew clean build'
            }
          }
        }
        stage('service-2') {
          steps {
            dir('src/backend2') {
              sh 'chmod +x gradlew'
              sh './gradlew clean build'
            }
          }
        }
      }
    }

    stage('Security & Tests') {
      parallel {
        stage('OWASP Dependency-Check') {
          steps {
            script {
              // prepare output dirs
              sh 'mkdir -p reports/owasp-service1 reports/owasp-service2'
              // scan service1
              sh '''
                docker run --rm \
                  -v "$PWD/src/backend1":/src \
                  -v "$PWD/reports/owasp-service1":/report \
                  owasp/dependency-check \
                  --project service1 \
                  --scan /src \
                  --format "ALL" \
                  --out /report
              '''
              // scan service2
              sh '''
                docker run --rm \
                  -v "$PWD/src/backend2":/src \
                  -v "$PWD/reports/owasp-service2":/report \
                  owasp/dependency-check \
                  --project service2 \
                  --scan /src \
                  --format "ALL" \
                  --out /report
              '''
            }
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
          sh "docker build --no-cache -t ${env.DOCKERHUB_USR}/frontend:${tag} src/frontend"
          sh "docker build --no-cache -t ${env.DOCKERHUB_USR}/service1:${tag} src/backend1"
          sh "docker build --no-cache -t ${env.DOCKERHUB_USR}/service2:${tag} src/backend2"

          sh "trivy image ${env.DOCKERHUB_USR}/frontend:${tag}  > trivy-frontend.txt"
          sh "trivy image ${env.DOCKERHUB_USR}/service1:${tag}  > trivy-service1.txt"
          sh "trivy image ${env.DOCKERHUB_USR}/service2:${tag}  > trivy-service2.txt"
        }
      }
    }

    stage('Push & Update GitOps') {
      steps {
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
        to:      'sathwik.shetty@kickdrumtech.com,manav.verma@kickdrumtech.com,yashnitin.thakre@kickdrumtech.com,akashkumar.verma@kickdrumtech.com',
        subject: "Build SUCCESS #${env.BUILD_NUMBER}",
        body:    "✅ Build #${env.BUILD_NUMBER} succeeded!\n${env.BUILD_URL}",
        attachmentsPattern: 'trivy-*.txt'
      )
    }
  }
}
