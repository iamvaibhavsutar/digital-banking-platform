// Starter pipeline. Set AWS_ACCOUNT / GITOPS_REPO / credentials IDs to match your Jenkins.
pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }
  environment {
    AWS_REGION  = 'ap-south-1'
    AWS_ACCOUNT = '<ACCOUNT_ID>'
    REGISTRY    = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    GITOPS_REPO = 'github.com/iamvaibhavsutar/digital-banking-gitops.git'
    SERVICES    = 'account-service transfer-service'
    TAG         = "b${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7)}"
  }
  stages {
    stage('Unit tests') {
      steps {
        script { SERVICES.split(' ').each { s -> dir("services/${s}") { sh 'mvn -q test' } } }
      }
    }
    stage('Trivy source scan') {
      steps { sh 'trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --exit-code 1 --ignore-unfixed .' }
    }
    stage('Build images') {
      steps {
        script { SERVICES.split(' ').each { s -> sh "docker build -t ${REGISTRY}/${s}:${TAG} services/${s}" } }
      }
    }
    stage('Trivy image scan') {
      steps {
        script { SERVICES.split(' ').each { s ->
          sh "trivy image --severity HIGH,CRITICAL --exit-code 1 --ignore-unfixed ${REGISTRY}/${s}:${TAG}" } }
      }
    }
    stage('Push to ECR') {
      when { branch 'main' }
      steps {
        sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY'
        script { SERVICES.split(' ').each { s -> sh "docker push ${REGISTRY}/${s}:${TAG}" } }
      }
    }
    stage('GitOps bump') {
      when { branch 'main' }
      steps {
        withCredentials([string(credentialsId: 'github-gitops-token', variable: 'GH_TOKEN')]) {
          sh '''
            rm -rf gitops && git clone https://${GH_TOKEN}@${GITOPS_REPO} gitops
            cd gitops
            for s in $SERVICES; do sed -i "s|^\\(\\s*tag:\\).*|\\1 ${TAG}|" values/$s.yaml; done
            git config user.email ci@bankdemo.local && git config user.name jenkins
            git commit -am "ci: deploy ${TAG}" && git push origin HEAD:main
          '''
        }
      }
    }
    stage('Verify') {
      when { branch 'main' }
      steps {
        sh '''
          sleep 90
          curl -fsS http://${ALB_DNS_NAME}/api/accounts/ACC1001
        '''
      }
    }
  }
  post {
    failure {
      script {
        if (env.BRANCH_NAME == 'main') {
          withCredentials([string(credentialsId: 'github-gitops-token', variable: 'GH_TOKEN')]) {
            sh '''
              if [ -d gitops ]; then cd gitops && git revert --no-edit HEAD && git push origin HEAD:main; fi
            '''
          }
        }
      }
    }
    always { sh 'docker image prune -f || true' }
  }
}
