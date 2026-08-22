#!/bin/bash

# The Architecture of Leverage: Define the static variables
ACCOUNT_ID="767397659229"
REGION="us-east-1"
PROFILE="tf-deployer"
REPO_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# The Target Array: The remaining 9 microservices
SERVICES=(
  "cartservice"
  "currencyservice"
  "paymentservice"
  "shippingservice"
  "emailservice"
  "checkoutservice"
  "recommendationservice"
  "adservice"
  "shoppingassistantservice"
)

echo "Authenticating with AWS ECR..."
aws ecr get-login-password --region $REGION --profile $PROFILE | docker login --username AWS --password-stdin $REPO_URL

# The Engine: Loop through the array and execute the build/push lifecycle
for service in "${SERVICES[@]}"; do
  echo "=========================================================="
  echo "COMMENCING BUILD: $service"
  echo "=========================================================="
  
  # Navigate to the source code (Adjust this path if your script is in a different folder relative to 'src')
  cd src/$service || { echo "Directory src/$service not found. Exiting."; exit 1; }
  
  # Build, Tag, and Push
  docker build -t $service:latest .
  docker tag $service:latest $REPO_URL/$service:latest
  docker push $REPO_URL/$service:latest
  
  # Return to the previous directory
  cd - > /dev/null
done

echo "=========================================================="
echo "MASS DEPLOYMENT COMPLETE."
echo "=========================================================="