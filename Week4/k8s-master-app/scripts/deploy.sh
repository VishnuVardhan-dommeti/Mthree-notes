#!/bin/bash
# Deployment script for the Kubernetes Zero to Hero application
# This script automates the entire deployment process to Minikube
# REVISED VERSION: Works around WSL2 mounting limitations

# Color definitions for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}             KUBERNETES ZERO TO HERO - DEPLOYMENT                     ${NC}"
echo -e "${BLUE}======================================================================${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Step 1: Check prerequisites
echo -e "${MAGENTA}[STEP 1] CHECKING PREREQUISITES${NC}"

# Check for required tools
for tool in minikube kubectl docker; do
    if ! command_exists $tool; then
        echo -e "${RED}Error: $tool is not installed. Please install it and try again.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ $tool is installed${NC}"
done

# Step 2: Ensure Minikube is running
echo -e "${MAGENTA}[STEP 2] ENSURING MINIKUBE IS RUNNING${NC}"

if ! minikube status | grep -q "host: Running"; then
    echo -e "${YELLOW}Minikube is not running. Starting Minikube...${NC}"
    
    # Start Minikube with appropriate configuration
    # REMOVED mounting that caused issues
    minikube start --force --cpus=2 --memory=4096 --disk-size=20g
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to start Minikube. Trying with minimal configuration...${NC}"
        # Fallback to minimal configuration
        minikube start --driver=docker
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to start Minikube. Exiting.${NC}"
            exit 1
        fi
    fi
else
    echo -e "${GREEN}✓ Minikube is already running${NC}"
fi

# Step 3: Enable required Minikube addons
echo -e "${MAGENTA}[STEP 3] ENABLING MINIKUBE ADDONS${NC}"

# We'll handle addons more carefully, checking if they're already enabled
# and handling errors better

# Function to safely enable an addon
enable_addon() {
    local addon=$1
    local already_enabled=$(minikube addons list | grep $addon | grep -c "enabled")
    
    if [ $already_enabled -eq 1 ]; then
        echo -e "${GREEN}✓ $addon addon is already enabled${NC}"
        return 0
    fi
    
    echo -e "${CYAN}Enabling $addon addon...${NC}"
    minikube addons enable $addon
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Warning: Failed to enable $addon addon. Continuing without it.${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $addon addon enabled${NC}"
        return 0
    fi
}

# Try to enable addons but don't fail if they don't work
enable_addon "dashboard" || true

echo -e "${YELLOW}Note: Skipping Ingress and Metrics Server addons as they may not work in all environments${NC}"
echo -e "${YELLOW}The application will still work without these addons${NC}"

# Step 4: Configure Docker to use Minikube's Docker daemon
echo -e "${MAGENTA}[STEP 4] CONFIGURING DOCKER TO USE MINIKUBE${NC}"
echo -e "${CYAN}This allows us to build images directly into Minikube's registry${NC}"

eval $(minikube docker-env)
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to configure Docker to use Minikube. Exiting.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker configured to use Minikube's registry${NC}"

# Step 5: Build the Docker image
echo -e "${MAGENTA}[STEP 5] BUILDING DOCKER IMAGE${NC}"

echo -e "${CYAN}Building k8s-master-app:latest image...${NC}"
cd ~/k8s-master-app/app
docker build -t k8s-master-app:latest .

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build Docker image. Exiting.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker image built successfully${NC}"
docker images | grep k8s-master-app

# Step 6: Apply Kubernetes manifests
echo -e "${MAGENTA}[STEP 6] DEPLOYING TO KUBERNETES${NC}"
cd ~/k8s-master-app

echo -e "${CYAN}Creating namespace...${NC}"
kubectl apply -f k8s/base/namespace.yaml

echo -e "${CYAN}Creating ConfigMap and sample files...${NC}"
kubectl apply -f k8s/volumes/volumes.yaml

echo -e "${CYAN}Creating ConfigMap for application settings...${NC}"
kubectl apply -f k8s/config/configmap.yaml

echo -e "${CYAN}Creating Secret...${NC}"
kubectl apply -f k8s/config/secret.yaml

echo -e "${CYAN}Creating Deployment...${NC}"
kubectl apply -f k8s/base/deployment.yaml

echo -e "${CYAN}Creating Service...${NC}"
kubectl apply -f k8s/networking/service.yaml

echo -e "${CYAN}Creating HorizontalPodAutoscaler...${NC}"
kubectl apply -f k8s/monitoring/hpa.yaml || true
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Warning: Failed to create HorizontalPodAutoscaler. This is expected if metrics-server is not enabled.${NC}"
    echo -e "${YELLOW}The application will still work without auto-scaling.${NC}"
fi

echo -e "${GREEN}✓ All Kubernetes resources applied${NC}"

# Step 7: Wait for deployment to be ready
echo -e "${MAGENTA}[STEP 7] WAITING FOR DEPLOYMENT TO BE READY${NC}"
echo -e "${CYAN}This may take a minute or two...${NC}"

echo "Waiting for deployment to be ready..."
kubectl -n k8s-demo rollout status deployment/k8s-master-app --timeout=180s

if [ $? -ne 0 ]; then
    echo -e "${RED}Deployment failed to become ready within the timeout period.${NC}"
    echo -e "${YELLOW}Checking pod status...${NC}"
    kubectl -n k8s-demo get pods
    
    echo -e "${YELLOW}Checking pod logs...${NC}"
    POD=$(kubectl -n k8s-demo get pods -l app=k8s-master -o name | head -1)
    if [ ! -z "$POD" ]; then
        kubectl -n k8s-demo logs $POD
    fi
else
    echo -e "${GREEN}✓ Deployment is ready${NC}"
fi

# Step 8: Set up port forwarding for easier access
echo -e "${MAGENTA}[STEP 8] SETTING UP PORT FORWARDING${NC}"
echo -e "${CYAN}This will make the application accessible on localhost${NC}"

# Check if port forwarding is already running
if pgrep -f "kubectl.*port-forward.*k8s-demo" > /dev/null; then
    echo -e "${YELLOW}Port forwarding is already running. Stopping it...${NC}"
    pkill -f "kubectl.*port-forward.*k8s-demo"
fi

# Start port forwarding in the background
kubectl -n k8s-demo port-forward svc/k8s-master-app 8080:80 &
PORT_FORWARD_PID=$!

# Give it a moment to start
sleep 2

# Check if port forwarding started successfully
if ! ps -p $PORT_FORWARD_PID > /dev/null; then
    echo -e "${RED}Failed to start port forwarding.${NC}"
else
    echo -e "${GREEN}✓ Port forwarding started on port 8080${NC}"
fi

# Step 9: Display access information
echo -e "${MAGENTA}[STEP 9] DEPLOYMENT COMPLETE${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "${GREEN}Kubernetes Zero to Hero application has been deployed!${NC}"
echo -e "${BLUE}======================================================================${NC}"

echo -e "${YELLOW}Your application is accessible via multiple methods:${NC}"
echo ""
echo -e "${CYAN}1. Port Forwarding:${NC}"
echo "   URL: http://localhost:8080"
echo "   (This is running in the background with PID $PORT_FORWARD_PID)"
echo ""

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo -e "${CYAN}2. NodePort:${NC}"
echo "   URL: http://$MINIKUBE_IP:30080"
echo ""

echo -e "${CYAN}3. Minikube Service URL:${NC}"
echo "   Run: minikube service k8s-master-app -n k8s-demo"
echo ""

# Step 10: Display useful commands
echo -e "${BLUE}======================================================================${NC}"
echo -e "${YELLOW}USEFUL COMMANDS:${NC}"
echo -e "${BLUE}======================================================================${NC}"

echo -e "${CYAN}View the Kubernetes Dashboard:${NC}"
echo "   minikube dashboard"
echo ""
echo -e "${CYAN}View application logs:${NC}"
echo "   kubectl -n k8s-demo logs -l app=k8s-master"
echo ""
echo -e "${CYAN}Get a shell into a pod:${NC}"
echo "   kubectl -n k8s-demo exec -it $(kubectl -n k8s-demo get pods -l app=k8s-master -o name | head -1) -- /bin/bash"
echo ""
echo -e "${CYAN}View all resources in the namespace:${NC}"
echo "   kubectl -n k8s-demo get all"
echo ""
echo -e "${CYAN}Check pod resource usage (if metrics-server is enabled):${NC}"
echo "   kubectl -n k8s-demo top pods"
echo ""
echo -e "${CYAN}Clean up all resources:${NC}"
echo "   ./scripts/cleanup.sh"
echo ""
echo -e "${CYAN}Stop port forwarding:${NC}"
echo "   kill $PORT_FORWARD_PID"
echo ""

echo -e "${BLUE}======================================================================${NC}"
echo -e "${GREEN}DEPLOYMENT SUCCESSFUL!${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "${YELLOW}Enjoy exploring your Kubernetes application!${NC}"
