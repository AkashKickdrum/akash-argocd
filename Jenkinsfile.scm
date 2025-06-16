// Jenkinsfile.scm
pipeline {
  agent any

  environment {
    DOCKERHUB = credentials('dockerhub-creds')
    GIT_SSH   = 'git-ssh'
    SONARQ    = 'SonarQube'
  }

  stages {
    stage('Cleanup') { steps { deleteDir() } }

    stage('Checkout') {
      steps {
        git(
          url: 'git@github.com:AkashKickdrum/akash-argocd.git',
          credentialsId: GIT_SSH,
          branch: 'main'
        )
      }
    }

    stage('Build & Test Backends') {
      parallel {
        stage('service-1') {
          steps {
            dir('src/backend1') {
              sh './gradlew clean build'
              sh './gradlew test'
            }
          }
        }
        stage('service-2') {
          steps {
            dir('src/backend2') {
              sh './gradlew clean build'
              sh './gradlew test'
            }
          }
        }
      }
    }

    stage('Static Analysis & Security') {
      steps {
        // SonarQube
        withSonarQubeEnv(SONARQ) {
          sh 'sonar-scanner -Dsonar.projectKey=service1 -Dsonar.sources=src/backend1'
          sh 'sonar-scanner -Dsonar.projectKey=service2 -Dsonar.sources=src/backend2'
        }
        // OWASP
        sh 'dependency-check.sh --project service1 --scan src/backend1'
        sh 'dependency-check.sh --project service2 --scan src/backend2'
      }
    }

    stage('Docker & Trivy') {
      steps {
        script {
          def tag = "${env.BUILD_NUMBER}"
          // build
          sh "docker build --no-cache -t ${DOCKERHUB_USR}/service1:${tag} src/backend1"
          sh "docker build --no-cache -t ${DOCKERHUB_USR}/service2:${tag} src/backend2"
          // scan
          sh "trivy image ${DOCKERHUB_USR}/service1:${tag} > trivy-service1.txt"
          sh "trivy image ${DOCKERHUB_USR}/service2:${tag} > trivy-service2.txt"
          // push & cleanup
          withCredentials([usernamePassword(
              credentialsId: 'dockerhub-creds',
              usernameVariable: 'USER', passwordVariable: 'PASS'
          )]) {
            sh 'echo $PASS | docker login -u $USER --password-stdin'
            sh "docker push ${DOCKERHUB_USR}/service1:${tag}"
            sh "docker push ${DOCKERHUB_USR}/service2:${tag}"
            sh "docker image rm ${DOCKERHUB_USR}/service1:${tag}"
            sh "docker image rm ${DOCKERHUB_USR}/service2:${tag}"
          }
        }
      }
    }

    stage('Update GitOps Manifests') {
      steps {
        dir('gitops/helm-chart') {
          sh "sed -i 's/^  service1:.*/  service1:\\n    repository: ${DOCKERHUB_USR}\\/service1\\n    tag: \"${BUILD_NUMBER}\"/' values.yaml"
          sh "sed -i 's/^  service2:.*/  service2:\\n    repository: ${DOCKERHUB_USR}\\/service2\\n    tag: \"${BUILD_NUMBER}\"/' values.yaml"
        }
        sshagent([GIT_SSH]) {
          sh '''
            git add gitops/helm-chart/values.yaml
            git commit -m "ci: bump service1 & service2 tags to ${BUILD_NUMBER}"
            git push origin main
          '''
        }
      }
    }

    stage('Email Report') {
      steps {
        emailext(
          to:      'sathwik.shetty@kickdrumtech.com,manav.verma@kickdrumtech.com,yashnitin.thakre@kickdrumtech.com',
          cc:      'akashkumar.verma@kickdrumtech.com',
          subject: "Build #${BUILD_NUMBER} Report",
          body:    "Trivy scans attached.",
          attachmentsPattern: 'trivy-*.txt'
        )
      }
    }
  }

  post {
    failure {
      emailext(
        to:      'akashkumar.verma@kickdrumtech.com',
        subject: "Build FAILED #${BUILD_NUMBER}",
        body:    "Check Jenkins console output for details."
      )
    }
  }
}
