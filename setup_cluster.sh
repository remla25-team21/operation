#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Error handler function
error_handler() {
    echo -e "${RED}Error occurred at step $STEP_NUMBER. Setup failed.${NC}"
    exit 1
}

# Set up trap to catch errors
trap 'error_handler' ERR

# Initialize step counter
STEP_NUMBER=0

# Set Ansible configuration file location
export ANSIBLE_CONFIG="./ansible.cfg"
echo -e "${GREEN}Using Ansible config: $ANSIBLE_CONFIG${NC}"

# step 0: add dashboard.local to hosts file if not already present
STEP_NUMBER=1
if ! grep -q "dashboard.local" /etc/hosts; then
    echo -e "${YELLOW}Step 1/5: Adding dashboard.local to hosts file...${NC}"
    echo "127.0.0.1 dashboard.local" | sudo tee -a /etc/hosts > /dev/null
else
    echo -e "${YELLOW}Step 1/5: dashboard.local already exists in /etc/hosts${NC}"
fi

# Step 1: Start all VMs and perform general setup
STEP_NUMBER=2
echo -e "${YELLOW}Step 2/5: Starting virtual machines and performing general setup...${NC}"
echo "ctrl node-1 node-2" | xargs -n 1 -P 3 vagrant up --provision-with ansible_general_setup

# Step 2: Run ctrl.yaml on the controller node
STEP_NUMBER=3
echo -e "${YELLOW}Step 3/5: Setting up controller node...${NC}"
vagrant provision ctrl --provision-with ansible_ctrl_specific_setup

# Step 3: Run node.yaml on node-1 and node-2 in parallel
# Make sure the previous step is completed before executing this command
STEP_NUMBER=4
echo -e "${YELLOW}Step 4/5: Setting up worker nodes...${NC}"
echo "node-1 node-2" | xargs -n 1 -P 2 vagrant provision --provision-with ansible_node_specific_setup

# Step 4: Run finalization.yml on ctrl after nodes are setup
# Make sure the previous step is completed before executing this command
STEP_NUMBER=5
echo -e "${YELLOW}Step 5/5: Finalizing cluster setup...${NC}"
vagrant provision ctrl --provision-with ansible_ctrl_finalization

# Get Dashboard access token
echo -e "${YELLOW}Retrieving Kubernetes Dashboard access token...${NC}"
echo -e "${GREEN}Open your browser and navigate to: https://dashboard.local${NC} ${RED}HTTPS PROTOCOL ONLY!${NC}"
echo -e "${YELLOW}Your login token is:${NC}"

vagrant ssh -c "kubectl -n kubernetes-dashboard create token admin-user" ctrl

echo -e "${GREEN}All steps completed successfully!${NC}"