# ACTIVIRY.md

This file documents individual contributions to each assignment in the REMLA project by Group 21. 

## A1: Versions, Releases, and Containerization

### Bohong Lu

- `lib-version`: includes creating a version utility class, setting up automated releases via GitHub workflows, and ensuring version consistency across the project. 
- `app-service`: includes integrating `lib-version`, integrating REST endpoints for model inference, and configuring Docker deployment for backend operations.

- Created PR：
  - https://github.com/remla25-team21/lib-version/pull/1
  - https://github.com/remla25-team21/app/pull/11
  - https://github.com/remla25-team21/app/pull/8
  - https://github.com/remla25-team21/app/pull/6
  - https://github.com/remla25-team21/app/pull/3
  - https://github.com/remla25-team21/app/pull/1
- Approved PR: 
  - https://github.com/remla25-team21/lib-ml/pull/3
  - https://github.com/remla25-team21/model-service/pull/1
  - https://github.com/remla25-team21/lib-version/pull/1
  - https://github.com/remla25-team21/operation/pull/1
  - https://github.com/remla25-team21/operation/pull/2
  - https://github.com/remla25-team21/app/pull/5
  - https://github.com/remla25-team21/app/pull/4
  - https://github.com/remla25-team21/app/pull/2

### Kanta Tanahashi

- Implemented the `model-service`, configuring the workflow and embedding the trained model from `model-training` and exposing it via a REST endpoint.  
- Worked on the `operation` repository to orchestrate and document the full system.

- Created PR：
  - https://github.com/remla25-team21/model-service/pull/1
  - https://github.com/remla25-team21/operation/pull/1
  - https://github.com/remla25-team21/operation/pull/2
  - https://github.com/remla25-team21/app/pull/10
- Approved PR: https://github.com/remla25-team21/app/pull/8

### Raghav Talwar

- Worked on `app-frontend`: developed the frontend for the restaurant sentiment analysis app and integrated it with the `app-service` to handle responses from the `model-service`. 

- Created PR：
  - https://github.com/remla25-team21/app/pull/5
  - https://github.com/remla25-team21/app/pull/4,
  - https://github.com/remla25-team21/app/pull/2
- Approved PR: 
  - https://github.com/remla25-team21/model-training/pull/1
  - https://github.com/remla25-team21/app/pull/11
  - https://github.com/remla25-team21/app/pull/10
  - https://github.com/remla25-team21/app/pull/6
  - https://github.com/remla25-team21/app/pull/3
  - https://github.com/remla25-team21/app/pull/1

### Yizhen Zang

- Built the `model-training` pipeline, integrated `lib-ml`, and configured versioning and release workflows for trained models. 

- Created PR: 
  - https://github.com/remla25-team21/model-training/pull/1
  - https://github.com/remla25-team21/lib-ml/pull/3 
- Approved PR: https://github.com/remla25-team21/lib-ml/pull/2 

### Zeryab Alam

- Segregated out the data pre-processing code into its the `lib-ml`package, set up versioning and GitHub workflow, so it can be easily installed with pip and reused in both `model-training` and `model-service`. 

- Created PR：https://github.com/remla25-team21/lib-ml/pull/2 
- Approved PR: https://github.com/remla25-team21/model-service/pull/1 

## A2: Provisioning a Kubernetes Cluster

### Bohong Lu

- Collaborated with Kanta in *steps 15-17* to set up flannel as the network plugin for the cluster and set up Helm for package management.
- Implemented cluster infrastructure components including MetalLB for load balancing, Nginx Ingress Controller for routing, and Kubernetes Dashboard for monitoring and management in *steps 20-22*.

- Created PR：
  - https://github.com/remla25-team21/operation/pull/
- Approved PR: 
  - https://github.com/remla25-team21/operation/pull/5
  - https://github.com/remla25-team21/operation/pull/6

### Kanta Tanahashi

### Raghav Talwar

### Yizhen Zang

### Zeryab Alam

