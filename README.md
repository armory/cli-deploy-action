# Armory Project Borealis Deployment Action

## Overview

<!-- update the GHA readme or docs.armory.io page when making changes to one or the other -->

Project Borealis uses Armory's hosted cloud services to deploy Kubernetes applications to your clusters. When the GitHub Action triggers a deployment, the action sends a deployment request to Armory's hosted cloud services. In turn, the cloud services communicate with your Kubernetes cluster using Armory's Remote Network Agent (RNA) to initiate the deployment.

Borealis supports performing a canary deployment to deploy an app progressively to your cluster by setting weights (percentage thresholds) for the deployment and a pause after each weight is met. For example, you can deploy the new version of your app to 25% of your target cluster and then wait for a manual judgement or a configurable amount of time. This pause gives you time to assess the impact of your changes. From there, either continue the deployment to the next threshold you set or roll back the deployment.

All this logic is defined in a deployment file that you create and store in GitHub.

## Prerequisites

1. Review the full set of requirements for Borealis, see [System Requirements](https://docs.armory.io/borealis/borealis-requirements/).
2. Complete the [Get Started with Project Borealis](hhttps://docs.armory.io/borealis/quick-start/borealis-org-get-started/) tasks, which include the following:

  - Register for an Armory hosted cloud services account. This is the account that you use to log in to the Armory Cloud Console and the Status UI.
  - Create machine-to-machine client credentials for the Remote Network Agent (RNA), which gets installed on your deployment target.
  - Prepare your deployment target by installing the RNA.
  
3. In the Cloud Console, create machine-to-machine client credentials to use for your GitHub Action service account. For more information, see [Integrate Borealis & Automate Deployments](https://docs.armory.io/borealis/quick-start/borealis-integrate/)
4. Encrypt the GitHub Action service account credentials so that you can use them securely in the action. For more information, see [Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets.)

## Configure the action

> If you are new to using GitHub Actions, see [Quickstart for GitHub Actions](https://docs.github.com/en/actions/quickstart) for information about setting up GitHub Actions.
 
Save the following YAML file to your `.github/workflows` directory:

```yaml
name: <Descriptive Name>

on: 
  <trigger> # What triggers a deployment. For example, `push`.
    branches:
      - <branchName> # What branch triggers a deployment. For example, `main`.

jobs:
  build:
    name: <Descriptive Name>
    runs-on: ubuntu-latest
    steps:
      - name Checkout code
        uses: actions/checkout@v2

      - name Deployment
        uses: armory/cli-deploy-action@main
        with:
        clientId: "${{ secrets.CLIENTID }}" # Encrypted client ID that you created in the Armory Cloud Console that has been encrypted with GitHub's encrypted secrets.
        clientSecret:  "${{ secrets.CLIENTSECRET }}" #Client secret that you created in the Armory Cloud Console that has been encrypted with GitHub's encrypted secrets.
        path-to-file: "/path/to/deployment.yaml" # Path to the deployment file. For more information, see the Create a deployment file section.

```

## Create a deployment file

The deployment file is a YAML file that defines what to deploy and how Borealis deploys it. 

```yaml
version: v1
kind: kubernetes
application: <appName>
# Map of Deployment target
targets:
  # Name of the deployment.
  <name>:
    # The account name that a deployment target cluster got assigned when you installed the Remote Network Agent (RNA) on it.
    account: <accountName>
    # Optionally, override the namespaces that are in the manifests
    namespace:
    # This is the key that references a strategy you define under the strategies section of the file.
    strategy: <strategyName>
# The list of manifests sources
manifests:
  # A directory containing multiple manifests. Instructs Borealis to read all yaml|yml files in the directory and deploy all manifests to the target defined in `targets`.
  - path: /path/to/manifest/directory
  # This specifies a specific manifest file
  - path: /path/to/specific/manifest.yaml
# The map of strategies that you can use to deploy your app.
strategies:
  # The name for a strategy, which you use for the `strategy` key to select one to use.
  <strategyName>:
    # The deployment strategy type. As part of the early access program, Borealis supports `canary`.
    canary:
      # List of canary steps
      steps:
        # The map key is the step type. First configure `setWeight` for the weight (how much of the cluster the app should deploy to for a step).
        - setWeight:
            weight: <integer> # Deploy the app to <integer> percent of the cluster as part of the first step. `setWeight` is followed by a `pause`.
        - pause: # `pause` can be set to a be a specific amount of time or to a manual judgment.
            duration: <integer> # How long to wait before proceeding to the next step.
            unit: seconds # Unit for duration. Can be seconds, minutes, or hours.
        - setWeight:
            weight: <integer> # Deploy the app to <integer> percent of the cluster as part of the second step
        - pause:
            untilApproved: true # Pause the deployment until a manual approval is given. You can approve the step through the CLI or Status UI.
```

Note that you do not need to configure a `setWeight` step for `100`. Borealis automatically rolls out the deployment to the whole cluster after completing the final step you configure.

### Example deployment file

<details><summary>Show me an example deployment file</summary>

```yaml
version: v1
kind: kubernetes
application: ivan-nginx
# Map of deployment target
targets:
  # Name of the deployment.
  dev-west:
    # The account name that a deployment target cluster got assigned when you installed the Remote Network Agent (RNA) on it.
    account: cdf-dev
    # Optionally, override the namespaces that are in the manifests
    namespace: cdf-dev-agent
    # This is the key that references a strategy you define under the strategies section of the file.
    strategy: canary-wait-til-approved
# The list of manifests sources
manifests:
  # A directory containing multiple manifests. Instructs Borealis to read all yaml|yml files in the directory and deploy all manifests to the target defined in `targets`.
  - path: /deployments/manifests/configmaps
  # A specific manifest file that gets deployed to the target defined in `targets`.
  - path: /deployments/manifests/deployment.yaml
# The map of strategies that you can use to deploy your app.
strategies:
  # The name for a strategy, which you use for the `strategy` key to select one to use.
  canary-wait-til-approved:
    # The deployment strategy type. As part of the early access program, Borealis supports `canary`.
    canary:
      # List of canary steps
      steps:
      # The map key is the step type. First configure `setWeight` for the weight (how much of the cluster the app should deploy to for a step).
      - setWeight:
        - setWeight:
            weight: 33 # Deploy the app to 33% of the cluster.
        - pause: 
            duration: 60 # Wait 60 seconds before starting the next step.
            unit: seconds
        - setWeight:
            weight: 66 # Deploy the app to 66% of the cluster.
        - pause:
            untilApproved: true # Wait until approval is given through the Borealis CLI or Status UI.
```

</details>

## Deploy

When the action runs, Borealis starts your deployment, and it progresses to the first weight you set. After completing the first step, what Borealis does next depends on the steps you defined in your deployment file. Borealis either waits a set amount of time or until you provide a manual judgment and approval. 

You can monitor the progress through the Borealis CLI or the Status UI by using the deployment ID. The GitHub Action provides both the deployment ID and a URL to the Status UI page for the deployment.

**Borealis CLI**:

```bash
armory deploy status -i <deployment-ID>
```

**Status UI**

You need login credentials to access the Status UI, which is part of Armory's hosted cloud services. For the early access program, contact Armory for registration information.
