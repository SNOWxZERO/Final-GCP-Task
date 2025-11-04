#!/bin/bash
# Script to retrieve the Load Balancer IP after deployment

set -e

PROJECT_ID="iti-project-476212"
ZONE="us-central1-a"
VM_NAME="gad-final-task-management-vm"

echo "Fetching Load Balancer IP..."

LB_IP=$(gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --tunnel-through-iap \
  --project="$PROJECT_ID" \
  --command='kubectl get service demo-app-service -o jsonpath="{.status.loadBalancer.ingress[0].ip}" 2>/dev/null || echo ""')

if [ -n "$LB_IP" ]; then
  echo ""
  echo "========================================="
  echo "Load Balancer IP: $LB_IP"
  echo "Application URL: http://$LB_IP"
  echo "========================================="
  echo ""
  echo "Testing connection..."
  curl -I "http://$LB_IP" 2>/dev/null || echo "Note: Application may still be starting up"
else
  echo "Load Balancer IP not yet assigned."
  echo "The service may still be provisioning. Wait a few moments and try again."
  echo ""
  echo "To check manually, run:"
  echo "  gcloud compute ssh $VM_NAME --zone=$ZONE --tunnel-through-iap --project=$PROJECT_ID --command='kubectl get service demo-app-service'"
fi
