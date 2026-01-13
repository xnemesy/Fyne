#!/bin/bash

# Configuration
PROJECT_ID="fyne-484206"
REGION="europe-west8"
INSTANCE_NAME="main-db"
DB_VERSION="POSTGRES_15"
TIER="db-f1-micro" # Smallest tier for dev
NETWORK_NAME="fyne-vpc"

echo "🚀 Starting Infrastructure Provisioning for project: $PROJECT_ID"

# 1. Enable APIs
echo "Enabling necessary APIs..."
gcloud services enable compute.googleapis.com \
    sqladmin.googleapis.com \
    run.googleapis.com \
    servicenetworking.googleapis.com \
    firebase.googleapis.com \
    iam.googleapis.com \
    cloudresourcemanager.googleapis.com

# 2. Create VPC Network
echo "Creating VPC Network: $NETWORK_NAME"
gcloud compute networks create $NETWORK_NAME --subnet-mode=auto

# 3. Configure Private Service Access
echo "Allocating IP range for Private Service Access..."
gcloud compute addresses create fyne-sql-private-ip-range \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --description="PEERING-FOR-CLOUD-SQL" \
    --network=$NETWORK_NAME

echo "Creating Private Service Connection..."
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=fyne-sql-private-ip-range \
    --network=$NETWORK_NAME \
    --project=$PROJECT_ID

# 4. Provision Cloud SQL Instance (Private IP)
echo "Provisioning Cloud SQL Instance: $INSTANCE_NAME..."
gcloud beta sql instances create $INSTANCE_NAME \
    --project=$PROJECT_ID \
    --database-version=$DB_VERSION \
    --tier=$TIER \
    --region=$REGION \
    --network=$NETWORK_NAME \
    --no-assign-ip \
    --storage-type=SSD \
    --storage-size=10

# 5. Create Backend Service Role
echo "Creating Service Account for Backend..."
SA_NAME="backend-service-account"
gcloud iam service-accounts create $SA_NAME \
    --description="Service account for Cloud Run backend" \
    --display-name="Backend SA"

# Assign permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

echo "✅ Infrastructure Provisioning logic prepared."
echo "⚠️ Note: Ensure billing is enabled for the project before running."
