#!/bin/bash
# Cleanup script — run after testing is complete
# Usage: ./cleanup-aws.sh

set -euo pipefail

PROFILE="personal"
BUCKET="deployment-test-435236384656"
CF_DISTRIBUTION="ELFYVRGZFI053"
OAC_ID="E1YFFWYKTTYDTY"

echo "=== Cleaning up AWS resources ==="

echo "1. Emptying S3 bucket..."
aws s3 rm "s3://$BUCKET" --recursive --profile "$PROFILE"

echo "2. Deleting S3 bucket..."
aws s3 rb "s3://$BUCKET" --profile "$PROFILE"

echo "3. Disabling CloudFront distribution..."
ETAG=$(aws cloudfront get-distribution-config --id "$CF_DISTRIBUTION" --profile "$PROFILE" --query 'ETag' --output text)
aws cloudfront get-distribution-config --id "$CF_DISTRIBUTION" --profile "$PROFILE" --query 'DistributionConfig' --output json \
  | jq '.Enabled = false' > /tmp/cf-disable.json
aws cloudfront update-distribution --id "$CF_DISTRIBUTION" --if-match "$ETAG" --distribution-config file:///tmp/cf-disable.json --profile "$PROFILE" > /dev/null

echo "4. Waiting for distribution to be disabled (this takes a few minutes)..."
aws cloudfront wait distribution-deployed --id "$CF_DISTRIBUTION" --profile "$PROFILE"

echo "5. Deleting CloudFront distribution..."
ETAG=$(aws cloudfront get-distribution-config --id "$CF_DISTRIBUTION" --profile "$PROFILE" --query 'ETag' --output text)
aws cloudfront delete-distribution --id "$CF_DISTRIBUTION" --if-match "$ETAG" --profile "$PROFILE"

echo "6. Deleting Origin Access Control..."
ETAG=$(aws cloudfront get-origin-access-control --id "$OAC_ID" --profile "$PROFILE" --query 'ETag' --output text)
aws cloudfront delete-origin-access-control --id "$OAC_ID" --if-match "$ETAG" --profile "$PROFILE"

echo "=== All resources deleted ==="
