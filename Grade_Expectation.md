# Grade Expectation Summary

This file summarizes the expected rubric outcomes for the project, according to the grading criteria outlined in the course.

---
# Assignment 1
## ✅ Basic Requirements

### Data Availability: **Pass**
- The GitHub organization follows the required structure.
- `operation` repository contains a `README.md` with all necessary deployment instructions.

### Sensible Use Case: **Pass**
- The frontend allows querying the model and supports additional interactions like feedback/flagging for continuous experimentation.

---

## ✅ Versioning & Releases

### Automated Release Process: **Good**
- All artifacts (model-service image, app image, libraries) are versioned and released.
- GitHub workflows are used to automate the release.
- Git release tags (e.g., `v1.2.3`) are used to version artifacts.

### Software Reuse in Libraries: **Excellent**
- Both `lib-version` and `lib-ml` are reused as external dependencies via package managers.
- `lib-ml` contains shared logic between training and inference.
- `lib-version` is automatically updated in the release pipeline.
- Model is downloaded at container start using a specific version URL passed via an ENV variable.
- A local cache ensures models are not re-downloaded unnecessarily.

---

## ✅ Containers & Orchestration

### Exposing a Model via REST: **Excellent**
- All components communicate using REST.
- `Flask` serves the model.
- The ENV variable defines DNS and port of model-service.
- API conforms to OpenAPI Spec with endpoint summaries, parameters, and responses.
- Model-service port is configurable via an ENV variable.

### Docker Compose Operation: **Excellent**
- `docker-compose.yml` exists and supports complete local operation of the system.
- Only `app-service` is exposed to the host.
- Includes volume mapping, port mapping, and environment variables.
- Same images as Kubernetes deployment are used.
- Restart policies are defined.
- Includes an example of a Docker secret.
- Uses `.env` file for configuration.

---

### 🏁 Summary of Expected Rubric Grades

| Rubric Section                     | Subsection                       | Expected Grade |
|----------------------------------- |----------------------------------|----------------|
| Basic Requirements                 | Data Availability                | Pass           |
|                                    | Sensible Use Case                | Pass           |
| Versioning & Releases              | Automated Release Process        | Good           |
|                                    | Software Reuse in Libraries      | Excellent      |
| Containers & Orchestration         | Exposing a Model via REST        | Excellent      |
|                                    | Docker Compose Operation         | Excellent      |


# Assignment 2

## ✅ Provisioning

### Setting up (Virtual) Infrastructure: **Excellent**
- All expected VMs exist and are booted with the correct hostnames.
- VMs are on a private network and can communicate directly with each other.
- Host-only network allows all VMs to be accessed from the host without port forwarding.
- Provisioning uses Ansible and completes within 5 minutes.
- `Vagrantfile` defines VMs using loops and template arithmetic for names and IPs.
- CPU cores, memory, and the number of workers are controlled via variables.
- Extra arguments are passed from Vagrant to Ansible.
- A correct `inventory.cfg` is generated automatically and includes only active VMs.

### Setting up Software Environment: **Excellent**
- Ansible playbooks install packages with `apt`, start and enable services.
- Files are copied into VMs, and configurations are edited.
- Built-in modules are used with idempotency.
- Variables are registered and reused across tasks.
- Tasks include loops (e.g., copying multiple SSH keys).
- Re-provisioning does not reset the cluster.
- A correct `/etc/hosts` file is generated, containing only existing nodes.
- Wait conditions are included for slow processes (e.g., MetalLB).
- Idempotent regex replacements are used in config files.

### Setting up Kubernetes: **Excellent**
- `kubectl` config is copied to both the controller and the host.
- Host-based `kubectl` can apply/delete resources directly.
- Vagrant user has a working `kubectl` setup on the controller.
- All in-class Kubernetes and Istio exercises can be deployed and work correctly.
- MetalLB is installed and provides LoadBalancer IPs.
- HTTP Ingress Controller (e.g., Nginx) works and has a fixed IP.
- Istio Gateway is operational with a fixed IP.
- Kubernetes Dashboard is accessible from the host without SSH tunneling.
- HTTPS Ingress Controller with self-signed certificates is set up.

---

## 🏁 Summary of Expected Rubric Grades

| Rubric Section           | Subsection                         | Expected Grade |
|--------------------------|------------------------------------|----------------|
| Provisioning             | Setting up (Virtual) Infrastructure| Excellent      |
|                          | Setting up Software Environment    | Excellent      |
|                          | Setting up Kubernetes              | Excellent      |

# Assignment 3

## ✅ Kubernetes & Monitoring

## Kubernetes Usage: **Excellent**
- The application is deployed to a Kubernetes cluster with a working Deployment and Service.
- The app is accessible through an Ingress and an IngressController.
- The model service location is defined through an environment variable.
- The model service can be relocated by updating the Kubernetes config (e.g., changing the service name or port).
- A ConfigMap and Secret are used appropriately to demonstrate knowledge of Kubernetes resources.
- All VMs mount the same shared VirtualBox folder (`./shared`) to `/mnt/shared` inside the VM. 
- The `model-service-v1` Deployment mounts the shared path using a Kubernetes `hostPath` volume, making shared host storage accessible from within the container at `/app/shared`. 

## Helm Installation: **Excellent**
- The Helm chart covers the complete deployment.
- The chart uses `values.yaml` to allow customization of elements such as the model service DNS name.
- The Helm chart supports multiple installations into the same cluster.
- Prefixes are used for names and labels, especially in Deployments and Pods.

## App Monitoring: **Excellent**
- The app exposes 3+ custom metrics related to user behavior or model performance.
- Metric types include: Gauge, Counter, and Histogram.
- Each metric uses labels to break down data for detailed insights.
- Prometheus automatically discovers and collects the metrics using `ServiceMonitor` resources or appropriate labels.
- An `AlertManager` is configured with at least one non-trivial `PrometheusRule`.
- Alerts are raised through a communication channel (e.g., email).
- Secrets (e.g., SMTP credentials) are not hardcoded and are injected via environment variables from Kubernetes Secrets.

## Grafana Dashboard: **Excellent**
- A complete Grafana dashboard is defined and deployed automatically (e.g., using a ConfigMap).
- The dashboard includes panels for all app-specific metrics: Gauges, Counters, and Histograms.
- Timeframe selectors are used to parameterize dashboard queries.
- Functions such as `rate()` and `avg()` are applied to enhance visualization and analysis.

---

## 🏁 Summary of Expected Rubric Grades

| Rubric Section             | Subsection             | Expected Grade |
|----------------------------|------------------------|----------------|
| Kubernetes & Monitoring    | Kubernetes Usage       | Excellent      |
|                            | Helm Installation      | Excellent      |
|                            | App Monitoring         | Excellent      |
|                            | Grafana Dashboard      | Excellent      |

# Assignment 4

## ✅ ML Testing

### Automated Tests: **Excellent**
- Tests follow the **ML Test Score** methodology.
- Each test category is represented:
  - Feature and Data
  - Model Development
  - ML Infrastructure
  - Monitoring
- Tests for **non-determinism robustness** and **data slice-based evaluation** are included.
- **Non-functional requirements** such as memory and performance are tested.
- Feature cost is tested for inference overhead.
- **Test adequacy is measured and reported** during test runs.
- **Test coverage** is automatically measured using tools such as `coverage.py`.
- Includes an implementation of **metamorphic testing** with automatic inconsistency detection and repair.

### Continuous Training: **Excellent**
- Tests and linting are run **automatically via GitHub workflows**.
- On every push:
  - `pytest` executes all tests.
  - `pylint` is triggered.
- The workflow also:
  - Calculates and logs **test adequacy metrics** (e.g., ML Test Score).
  - Measures test coverage.
  - Publishes and updates test adequacy, coverage, and pylint score **as badges in the README**.

---

## ✅ ML Configuration Management

### Project Organization: **Excellent**
- The code is a structured Python project, **notebooks and scripts are modularized**.
- Pipeline stages (e.g., training, data preparation, evaluation) are separated and clearly defined.
- Dependencies are managed in a `requirements.txt`.
- The layout is inspired by the **Cookiecutter Data Science template**.
- **Exploratory code is isolated** from the production pipeline.
- **Datasets are automatically downloaded** and not stored in the repo.
- The final model is **packaged and published as a versioned GitHub release**.

### Pipeline Management with DVC: **Excellent**
- A complete DVC pipeline is implemented and **reproducible with `dvc repro`**.
- **Remote storage is cloud-based** (e.g., Google Drive), and setup instructions are provided in the README.
- Pipeline is versioned and **rollback is possible**.
- Model accuracy and **other metrics are computed and stored in JSON files**.
- Metrics are **registered in pipeline stages**.
- Running `dvc exp show` displays **multiple experiments and metrics beyond accuracy**.

### Code Quality: **Excellent**
- The project uses a **custom non-standard `pylint` configuration** and passes with no warnings.
- Multiple linters are used:
  - `flake8`
  - `bandit`
- Each linter uses **non-default configurations**.
- **Custom `pylint` rules are implemented** to catch ML-specific code smells.

---

## 🏁 Summary of Expected Rubric Grades

| Rubric Section                   | Subsection                    | Expected Grade |
|----------------------------------|-------------------------------|----------------|
| ML Testing                       | Automated Tests               | Excellent      |
|                                  | Continuous Training           | Excellent      |
| ML Configuration Management      | Project Organization          | Excellent      |
|                                  | Pipeline Management with DVC  | Excellent      |
|                                  | Code Quality                  | Excellent      |

# Assignment 5

## ✅ Implementation

### Traffic Management: **Excellent**
- The project implements **Sticky Sessions**, ensuring requests from the same origin have stable routing.
- A **Gateway** and **VirtualServices** are defined.
- The application is accessible through the IngressGateway (e.g., via `minikube tunnel`).
- Uses **DestinationRules and weights** to enable 90/10 routing for the app service.
- Versions of `model-service` and app are consistent.

### Additional Use Case: **Excellent**
- One of the described additional use cases (**Rate limiting**) has been **fully realized** with complete and observable effects.

### Continuous Experimentation: **Excellent**
- Documentation thoroughly explains the experiment:
  - Implemented changes.
  - Expected effects.
  - Relevant metrics tailored to the experiment.
- Two deployed versions of at least one container image exist and are reachable.
- The system implements metrics allowing hypothesis exploration.
- **Prometheus** collects the metrics.
- **Grafana** dashboard visualizes the experiment differences and supports the decision process.
- Documentation contains screenshots of the dashboard.
- The decision process for accepting or rejecting the experiment is detailed and clear, including criteria and how the dashboard supports the decision.

---

## ✅ Documentation

### Deployment Documentation: **Excellent**
- Documentation clearly describes:
  - Deployment structure including entities and their connections.
  - Data flow for incoming requests.
  - Points where dynamic routing decisions occur.
- Includes visualizations connected to the text.
- Covers all deployed resource types and their relations.
- Visually appealing and clear enough that a new team member could contribute to design discussions after studying it.

### Extension Proposal: **Excellent**
- Describes a genuine release-engineering-related shortcoming of project practices.
- Proposed extension addresses this shortcoming connected to an assignment topic.
- Critically reflects on the shortcoming, elaborates on its negative effects.
- Explains how the extension improves the shortcoming and how improvement can be measured objectively in an experiment.
- The extension is general and applicable beyond this project.
- Clearly overcomes the described shortcoming.
- Cites external sources inspiring the extension.

---

## 🏁 Summary of Expected Rubric Grades

| Rubric Section           | Subsection                | Expected Grade |
|--------------------------|-------------------------- |----------------|
| Implementation           | Traffic Management        | Excellent      |
|                          | Additional Use Case       | Excellent      |
|                          | Continuous Experimentation| Excellent      |
| Documentation            | Deployment Documentation  | Excellent      |
|                          | Extension Proposal        | Excellent      |