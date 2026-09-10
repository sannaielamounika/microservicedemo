# Speshway Production Microservices CI/CD Pipeline Documentation

## Repository & Infrastructure
- **Repository URL**: `https://github.com/sannaielamounika/microservicedemo`
- **Deployment Server IP**: `100.58.251.36` (Jenkins Controller & App Deployment host)
- **Target Environment**: `test` (AWS EKS Cluster: `speshway-test-eks`)

---

## Pipeline Workflow

```
GitHub Push -> Webhook (http://100.58.251.36:8080/github-webhook/)
   ↓
Jenkins Controller (100.58.251.36)
   │
   ├── CI Phase
   │    ├── 1. Checkout SCM
   │    ├── 2. Detect Changed Microservices
   │    ├── 3. Maven Compile Build
   │    ├── 4. Unit Testing
   │    ├── 5. SonarQube Static Analysis
   │    ├── 6. SonarQube Quality Gate Decision
   │    ├── 7. Docker Build (tagged with Git SHA)
   │    ├── 8. Trivy Security Vulnerability Scan
   │    └── 9. Push Container Images to AWS ECR
   │
   └── CD Phase
        ├── 10. Load Existing Helm Chart
        ├── 11. Inject Image & Tag Overrides
        ├── 12. Helm Upgrade/Install into Test EKS
        ├── 13. Wait for Kubernetes Pod Rollout Status
        └── 14. Execute Automated Endpoint Smoke Tests
```

---

## GitHub Webhook Integration Steps

1. Go to repository: `https://github.com/sannaielamounika/microservicedemo`
2. Click **Settings > Webhooks > Add webhook**.
3. Set **Payload URL**: `http://100.58.251.36:8080/github-webhook/`
4. Set **Content type**: `application/json`
5. Select event: **Just the `push` event**.
6. Click **Add webhook**.

---

## Jenkins Job Setup (Deployment Server `100.58.251.36`)

1. Log in to Jenkins at `http://100.58.251.36:8080`.
2. Click **New Item**, enter `microservicedemo-test-pipeline`, select **Pipeline**, click **OK**.
3. Under **Build Triggers**, check **GitHub hook trigger for GITScm polling**.
4. Under **Pipeline**:
   - **Definition**: `Pipeline script from SCM`
   - **SCM**: `Git`
   - **Repository URL**: `https://github.com/sannaielamounika/microservicedemo.git`
   - **Branch Specifier**: `*/master`
   - **Script Path**: `jenkins/Jenkinsfile`
5. Click **Save**.
