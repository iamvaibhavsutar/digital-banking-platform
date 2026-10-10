// Declarative pipeline for the monorepo. Configure in Jenkins:
//   Global env:   ALB_DNS_NAME, AWS_ACCOUNT
//   Credentials:  github-gitops-token (secret text, scoped to the GitOps repo only)
// The Jenkins host uses its EC2 instance role for ECR (no stored AWS keys).
pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds(); timeout(time: 40, unit: 'MINUTES') }
  parameters {
    booleanParam(name: 'RUN_SONAR', defaultValue: false, description: 'Run SonarQube analysis (needs the sonar server + token configured)')
    booleanParam(name: 'RUN_ZAP',   defaultValue: true,  description: 'OWASP ZAP baseline scan after deploy (main only)')
  }
  environment {
    AWS_REGION  = 'ap-south-1'
    REGISTRY    = "${AWS_ACCOUNT}.dkr.ecr.ap-south-1.amazonaws.com"
    GITOPS_REPO = 'github.com/iamvaibhavsutar/digital-banking-gitops.git'
    JAVA_SERVICES = 'auth-service account-service transfer-service transaction-service notification-service'
    TAG = "b${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7)}"   // immutable: ECR rejects re-pushing a tag
  }
  stages {
    stage('Unit tests') {
      steps {
        script {
          def jobs = [:]
          env.JAVA_SERVICES.split(' ').each { s ->
            jobs[s] = { dir("services/${s}") { sh 'mvn -q -B test' } }
          }
          parallel jobs
        }
      }
    }
    stage('Integration tests (Testcontainers)') {
      when { branch 'main' }
      steps { dir('services/account-service') { sh 'mvn -q -B verify' } }   // needs the Docker socket on the agent
    }
    stage('SonarQube') {
      when { allOf { branch 'main'; expression { params.RUN_SONAR } } }
      steps {
        withSonarQubeEnv('sonar') {
          script { env.JAVA_SERVICES.split(' ').each { s -> dir("services/${s}") { sh 'mvn -q -B sonar:sonar' } } }
        }
        timeout(time: 5, unit: 'MINUTES') { waitForQualityGate abortPipeline: true }
      }
    }
    stage('Trivy source scan') {
      steps { sh 'trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --exit-code 1 --ignore-unfixed --skip-dirs target .' }
    }
    stage('Build images') {
      steps {
        script {
          env.JAVA_SERVICES.split(' ').each { s -> sh "docker build -t ${REGISTRY}/${s}:${TAG} services/${s}" }
          sh "docker build -t ${REGISTRY}/portal:${TAG} frontend/portal"
        }
      }
    }
    stage('Trivy image scan') {
      steps {
        script {
          (env.JAVA_SERVICES.split(' ') + ['portal']).each { s ->
            sh "trivy image --severity HIGH,CRITICAL --exit-code 1 --ignore-unfixed ${REGISTRY}/${s}:${TAG}"
          }
        }
      }
    }
    stage('Push to ECR') {
      when { branch 'main' }
      steps {
        sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY'
        script { (env.JAVA_SERVICES.split(' ') + ['portal']).each { s -> sh "docker push ${REGISTRY}/${s}:${TAG}" } }
      }
    }
    stage('GitOps bump') {
      when { branch 'main' }
      steps {
        withCredentials([string(credentialsId: 'github-gitops-token', variable: 'GH_TOKEN')]) {
          sh '''
            rm -rf gitops && git clone https://${GH_TOKEN}@${GITOPS_REPO} gitops
            cd gitops
            for f in values/*.yaml; do sed -i "s|^\\(\\s*tag:\\).*|\\1 ${TAG}|" "$f"; done
            git config user.email ci@bankdemo.local && git config user.name jenkins
            git commit -am "ci: deploy ${TAG}" && git push origin HEAD:main
          '''
        }
      }
    }
    stage('Verify') {
      when { branch 'main' }
      steps {
        // Argo CD syncs within ~3 min; poll the smoke-test account through the ALB.
        sh '''
          for i in $(seq 1 30); do
            if curl -fsS -m 5 http://${ALB_DNS_NAME}/api/accounts/ACC1001 >/dev/null; then echo "smoke OK"; exit 0; fi
            echo "waiting for rollout ($i/30)"; sleep 10
          done
          echo "smoke test FAILED"; exit 1
        '''
      }
    }
    stage('OWASP ZAP baseline') {
      when { allOf { branch 'main'; expression { params.RUN_ZAP } } }
      steps {
        sh 'docker run --rm -v $(pwd):/zap/wrk:rw ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t http://${ALB_DNS_NAME} -I -r zap-report.html'
        archiveArtifacts artifacts: 'zap-report.html', allowEmptyArchive: true
      }
    }
  }
  post {
    failure {
      script {
        if (env.BRANCH_NAME == 'main') {
          withCredentials([string(credentialsId: 'github-gitops-token', variable: 'GH_TOKEN')]) {
            // Roll the CLUSTER back by reverting the GitOps commit (Argo CD syncs the old tag).
            // The bad CODE is still on main: revert it in this repo too, or the next commit redeploys it.
            sh '''
              if [ -d gitops ]; then
                cd gitops && git pull --rebase origin main || true
                git log -1 --pretty=%s | grep -q "^ci: deploy ${TAG}" && git revert --no-edit HEAD && git push origin HEAD:main || true
              fi
            '''
          }
        }
      }
    }
    always { sh 'docker image prune -f || true' }
  }
}
