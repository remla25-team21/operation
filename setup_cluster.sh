#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Start and provision VMs
echo -e "${YELLOW}Step 1/3: Starting and provisioning virtual machines...${NC}"
vagrant up
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to start virtual machines${NC}"
    exit 1
fi
echo -e "${GREEN}Virtual machines provisioned successfully${NC}"

# Step 2: Finalize cluster setup
echo -e "${YELLOW}Step 2/3: Finalizing Kubernetes cluster setup...${NC}"
ansible-playbook -u vagrant -i ansible/inventory/inventory.cfg ansible/playbooks/finalization.yml --limit=ctrl
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Cluster setup failed${NC}"
    exit 1
fi
echo -e "${GREEN}Cluster setup completed${NC}"

# Step 3: Get Dashboard access token
echo -e "${YELLOW}Step 3/3: Retrieving Kubernetes Dashboard access token...${NC}"
echo -e "${GREEN}Open your browser and navigate to: https://dashboard.local${NC} ${RED} HTTPS PROTOCOL ONLY! ${NC}"
echo -e "${YELLOW}Your login token is:${NC}"
vagrant ssh -c "kubectl -n kubernetes-dashboard create token admin-user" ctrl

echo -e "${GREEN}All steps completed successfully!${NC}"
