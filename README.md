# Operation Repository

This is the central repository for a REMLA project by Group 21.  The application performs sentiment analysis on user feedback using a machine learning model.  This repository orchestrates the following components hosted in separate repositories:

- [`model-training`](https://github.com/remla25-team21/model-training): Contains the machine learning training pipeline.

- [`lib-ml`](https://github.com/remla25-team21/lib-ml): Contains data pre-processing logic used across components.

- [`model-service`](https://github.com/remla25-team21/model-service): A wrapper service for the trained ML model. Exposes API endpoints to interact with the model.

- [`lib-version`](https://github.com/remla25-team21/lib-version): A version-aware utility library that exposes version metadata.

- [`app`](https://github.com/remla25-team21/app): Contains the application frontend and backend (user interface and service logic).

## How to start the application
1. Clone the repository
   ```bash
   git clone https://github.com/remla25-team21/operation.git
   ```
2.  Navigate into the project directory.
3.  Clone the repository
     ```bash
     docker-compose pull && docker-compose up -d
     ```

The frontend will be available at http://localhost:3000 by default. You can open it up in your browser and type in your review. 

## Kubernetes Cluster Provisioning (Assignment 2)

These steps guide you through setting up the Kubernetes cluster on your local machine using Vagrant and Ansible, and deploying the Kubernetes Dashboard.

0.  **Pre-configuration**:
    Add the following line to your host machine's hosts file. This file is typically located at `/etc/hosts` on Linux and macOS, or `C:\Windows\System32\drivers\etc\hosts` on Windows.
    ```
    192.168.56.90  dashboard.local
    ```

1.  **Start and Provision Virtual Machines**:
    Open your terminal in the project's root directory (where the `Vagrantfile` is located) and run:
    ```bash
    vagrant up
    ```
    This command will create and configure the virtual machines for the controller and worker node(s) and run initial setup playbooks.

2.  **Finalize Cluster Setup**:
    Once `vagrant up` completes, run the following Ansible playbook to install MetalLB, Nginx Ingress, and the Kubernetes Dashboard:
    ```bash
    ansible-playbook -u vagrant -i ansible/inventory/inventory.cfg ansible/playbooks/finalization.yml --limit=ctrl
    ```

3.  **Access Kubernetes Dashboard**:
    *   After the playbook finishes, open your web browser and navigate to: `http://dashboard.local`
    *   You will be prompted for a token. To obtain the login token, run the following command in your terminal (on the host machine):
        ```bash
        vagrant ssh -c "kubectl -n kubernetes-dashboard create token admin-user" ctrl
        ```
    *   Copy the output token and paste it into the Kubernetes Dashboard login page.

## Known Bug: Port Conflict on macOS (AirPlay Receiver)

On macOS, the `app-service` currently binds statically to `localhost:5000`. However, macOS reserves port `5000` for the AirPlay Receiver feature by default. This causes the app-service to fail to start or bind to the port correctly during local development or testing. 

**Temporary Workaround**: 
1. Go to System Settings -> General -> Airdrop & Handoff and switch off Airplay Receiver. 
2. Go to terminal and use the following commands: `lsof -i :5000` `kill -9 <PID>` 

**Long Term Fix**: 

We plan to eventually change `app-service` to accomodate environment variables which should allow users to freely change ports via `docker-compose.yml` file. 

## Activity Tracking

We maintain an overview of each team member's contributions in [ACTIVITY.md](https://github.com/remla25-team21/operation/blob/docs/readme-update/ACTIVITY.md). 
