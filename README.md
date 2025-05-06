# Operation Repository

This is the central repository for a REMLA project by Group 21.  The application performs sentiment analysis on user feedback using a machine learning model.  This repository orchestrates the following components hosted in separate repositories:

- [`model-training`](https://github.com/remla25-team21/model-training): Contains the machine learning training pipeline.

- [`lib-ml`](https://github.com/remla25-team21/lib-ml): Contains data pre-processing logic used across components.

- [`model-service`](https://github.com/remla25-team21/model-service): A wrapper service for the trained ML model. Exposes API endpoints to interact with the model.

- [`lib-version`](https://github.com/remla25-team21/lib-version): A version-aware utility library that exposes version metadata.

- [`app`](https://github.com/remla25-team21/app): Contains the application frontend and backend (user interface and service logic).

# How to start the application
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

## Known Bug: Port Conflict on macOS (AirPlay Receiver)

On macOS, the `app-service` currently binds statically to `localhost:5000`. However, macOS reserves port `5000` for the AirPlay Receiver feature by default. This causes the app-service to fail to start or bind to the port correctly during local development or testing. 

**Temporary Workaround**: 
1. Go to System Settings -> General -> Airdrop & Handoff and switch off Airplay Receiver. 
2. Go to terminal and use the following commands: `lsof -i :5000` `kill -9 <PID>` 

**Long Term Fix**: 

We plan to eventually change `app-service` to accomodate environment variables which should allow users to freely change ports via `docker-compose.yml` file. 

# Activity Tracking

We maintain an overview of each team member's contributions in [ACTIVITY.md](https://github.com/remla25-team21/operation/blob/docs/readme-update/ACTIVITY.md). 
