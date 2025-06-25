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
    rm ctrl.log node-1.log node-2.log -rf
    exit 1
}

# Set up trap to catch errors
trap 'error_handler' ERR

# Initialize step counter
STEP_NUMBER=0

# Step 0: Check if parallel is installed
STEP_NUMBER=0
echo -e "${YELLOW}Step 0/4: Checking if parallel is installed...${NC}"
if ! command -v parallel &> /dev/null; then
    echo -e "${RED}Error: The 'parallel' package is not installed.${NC}"
    echo -e "${RED}Please install it using one of the following commands:${NC}"
    echo -e "${YELLOW}For Debian/Ubuntu:${NC} sudo apt-get install parallel"
    echo -e "${YELLOW}For Red Hat/CentOS:${NC} sudo yum install parallel"
    echo -e "${YELLOW}For macOS:${NC} brew install parallel"
    exit 1
else
    echo -e "${GREEN}Parallel is installed. Proceeding with setup.${NC}"
fi

# Set Ansible configuration file location
export ANSIBLE_CONFIG="./ansible.cfg"
echo -e "${GREEN}Using Ansible config: $ANSIBLE_CONFIG${NC}"

# Step 1: add dashboard.local to hosts file if not already present
STEP_NUMBER=1
echo -e "${YELLOW}Step 1/4: Checking if dashboard.local is in /etc/hosts...${NC}"
if ! grep -q "dashboard.local" /etc/hosts; then
    echo -e "${GREEN}Adding dashboard.local to hosts file...${NC}"
    echo "127.0.0.1 dashboard.local" | sudo tee -a /etc/hosts > /dev/null
else
    echo -e "${GREEN}dashboard.local already exists in /etc/hosts${NC}"
fi

# Step 2: Start all VMs and perform general setup
STEP_NUMBER=2
echo -e "${YELLOW}Step 2/4: Starting virtual machines and performing general setup...${NC}"
echo "ctrl node-1 node-2" | tr ' ' '\n' | parallel --jobs 3 --tag --linebuffer "vagrant up {} --provision-with ansible_general_setup 2>&1"

# Step 3: Run ctrl.yaml on controller node and node.yaml on worker nodes in parallel
STEP_NUMBER=3
echo -e "${YELLOW}Step 3/4: Setting up controller and worker nodes in parallel...${NC}"
echo -e "ctrl:ansible_ctrl_specific_setup node-1:ansible_node_specific_setup node-2:ansible_node_specific_setup" | 
  tr ' ' '\n' | 
  parallel --colsep ':' --jobs 3 --tag --linebuffer  "vagrant provision {1} --provision-with {2} 2>&1"

# Step 4: Run finalization.yml on ctrl after nodes are setup
STEP_NUMBER=4
echo -e "${YELLOW}Step 4/4: Finalizing cluster setup...${NC}"
vagrant provision ctrl --provision-with ansible_ctrl_finalization
vagrant ssh -c "kubectl apply -f kubernetes/rate-limit-vagrant.yaml" ctrl

# Get Dashboard access token
echo -e "${YELLOW}Retrieving Kubernetes Dashboard access token...${NC}"
echo -e "${GREEN}Open your browser and navigate to: https://dashboard.local${NC} ${RED}HTTPS PROTOCOL ONLY!${NC}"
echo -e "${YELLOW}Your login token is:${NC}"

vagrant ssh -c "kubectl -n kubernetes-dashboard create token admin-user" ctrl

echo -e "${GREEN}All steps completed successfully!${NC}"

# changed to not throw nan error when the files do not exist
rm -f ctrl.log node-1.log node-2.log
