#!/bin/bash

# Build and deploy script for the microservice
set -e

# Configuration
IMAGE_NAME="demo-microservice"
IMAGE_TAG="latest"
AWS_REGION="us-west-2"
ECR_REPOSITORY_URI=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_color() {
    echo -e "${1}${2}${NC}"
}

# Function to build Maven project
build_maven() {
    echo_color $YELLOW "Building Maven project..."
    if ! command -v mvn &> /dev/null; then
        echo_color $RED "Maven is not installed. Please install Maven first."
        exit 1
    fi
    
    cd microservice
    mvn clean package -DskipTests
    cd ..
    echo_color $GREEN "Maven build completed successfully"
}

# Function to build Docker image
build_docker() {
    echo_color $YELLOW "Building Docker image..."
    if ! command -v docker &> /dev/null; then
        echo_color $RED "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    cd microservice
    docker build -t $IMAGE_NAME:$IMAGE_TAG .
    cd ..
    echo_color $GREEN "Docker image built successfully"
}

# Function to setup ECR repository (if using ECR)
setup_ecr() {
    if [ "$1" = "ecr" ]; then
        echo_color $YELLOW "Setting up ECR repository..."
        
        # Create ECR repository if it doesn't exist
        aws ecr describe-repositories --repository-names $IMAGE_NAME --region $AWS_REGION 2>/dev/null || \
        aws ecr create-repository --repository-name $IMAGE_NAME --region $AWS_REGION
        
        # Get ECR login token
        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
        
        ECR_REPOSITORY_URI=$(aws ecr describe-repositories --repository-names $IMAGE_NAME --region $AWS_REGION --query 'repositories[0].repositoryUri' --output text)
        echo_color $GREEN "ECR repository setup completed: $ECR_REPOSITORY_URI"
    fi
}

# Function to push Docker image
push_docker() {
    if [ "$1" = "ecr" ]; then
        echo_color $YELLOW "Pushing image to ECR..."
        docker tag $IMAGE_NAME:$IMAGE_TAG $ECR_REPOSITORY_URI:$IMAGE_TAG
        docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
        echo_color $GREEN "Image pushed to ECR successfully"
    else
        echo_color $YELLOW "Skipping image push (local deployment)"
    fi
}

# Function to deploy to Kubernetes
deploy_k8s() {
    echo_color $YELLOW "Deploying to Kubernetes..."
    
    if ! command -v kubectl &> /dev/null; then
        echo_color $RED "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Update deployment image if using ECR
    if [ "$1" = "ecr" ] && [ ! -z "$ECR_REPOSITORY_URI" ]; then
        sed -i '' "s|image: demo-microservice:latest|image: $ECR_REPOSITORY_URI:$IMAGE_TAG|g" microservice/k8s/deployment.yaml
    fi
    
    kubectl apply -f microservice/k8s/deployment.yaml
    echo_color $GREEN "Kubernetes deployment completed"
    
    # Show deployment status
    echo_color $YELLOW "Deployment status:"
    kubectl get deployments
    kubectl get services
    kubectl get pods
}

# Main execution
echo_color $GREEN "Starting microservice build and deployment process..."

# Parse command line arguments
DEPLOYMENT_TYPE="local"
if [ "$1" = "ecr" ]; then
    DEPLOYMENT_TYPE="ecr"
fi

# Execute build and deployment steps
build_maven
build_docker
setup_ecr $DEPLOYMENT_TYPE
push_docker $DEPLOYMENT_TYPE
deploy_k8s $DEPLOYMENT_TYPE

echo_color $GREEN "Build and deployment process completed successfully!"

if [ "$DEPLOYMENT_TYPE" = "local" ]; then
    echo_color $YELLOW "Note: For local deployment, make sure to load the Docker image into your Kubernetes cluster:"
    echo_color $YELLOW "kind load docker-image $IMAGE_NAME:$IMAGE_TAG  # For kind cluster"
    echo_color $YELLOW "minikube image load $IMAGE_NAME:$IMAGE_TAG     # For minikube"
fi
