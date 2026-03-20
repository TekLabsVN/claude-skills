#!/usr/bin/env bash
# AWS S3 + CloudFront + IAM Setup Script
# Creates a locked-down S3 bucket, a scoped IAM user, and a CloudFront distribution with OAC.
# Credentials are saved locally — never printed to stdout.

set -euo pipefail

# ── Colour helpers ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Argument parsing ──────────────────────────────────────────────────────────
BUCKET_NAME=""
REGION=""
USERNAME=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --bucket)   BUCKET_NAME="$2"; shift 2 ;;
    --region)   REGION="$2";      shift 2 ;;
    --username) USERNAME="$2";    shift 2 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -z "$BUCKET_NAME" ]] && die "--bucket is required"
[[ -z "$REGION" ]]      && die "--region is required"
[[ -z "$USERNAME" ]]    && die "--username is required"

# ── Output directory (in user home, not printed as credentials) ──────────────
OUTPUT_DIR="$HOME/aws-setup-${BUCKET_NAME}"
mkdir -p "$OUTPUT_DIR"
chmod 700 "$OUTPUT_DIR"

CREDENTIALS_FILE="$OUTPUT_DIR/credentials.json"
SUMMARY_FILE="$OUTPUT_DIR/summary.txt"

# ── Prerequisite checks ───────────────────────────────────────────────────────
command -v aws  >/dev/null 2>&1 || die "AWS CLI not found. Install it first: https://aws.amazon.com/cli/"
command -v jq   >/dev/null 2>&1 || die "'jq' is required but not installed. Install with: brew install jq  OR  apt install jq"

info "Verifying AWS credentials..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) \
  || die "AWS credentials not configured or insufficient permissions. Run 'aws configure' first."
success "Authenticated as account $ACCOUNT_ID"

# ── Step 1: Create S3 bucket ──────────────────────────────────────────────────
info "Creating S3 bucket: $BUCKET_NAME in $REGION..."

if [[ "$REGION" == "us-east-1" ]]; then
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --output json > /dev/null
else
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" \
    --output json > /dev/null
fi
success "Bucket created"

# Block all public access
info "Blocking all public access on bucket..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
success "Public access blocked"

# Enable default server-side encryption (AES-256)
info "Enabling server-side encryption (AES-256)..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"},
      "BucketKeyEnabled": true
    }]
  }'
success "Encryption enabled"

# ── Step 2: Create IAM user and scoped policy ─────────────────────────────────
info "Creating IAM user: $USERNAME..."
aws iam create-user --user-name "$USERNAME" --output json > /dev/null
success "IAM user created"

BUCKET_ARN="arn:aws:s3:::${BUCKET_NAME}"

info "Attaching least-privilege policy (scoped to this bucket only)..."
POLICY_JSON=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
      "Resource": "${BUCKET_ARN}"
    },
    {
      "Sid": "ObjectAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion",
        "s3:DeleteObjectVersion"
      ],
      "Resource": "${BUCKET_ARN}/*"
    }
  ]
}
EOF
)

aws iam put-user-policy \
  --user-name "$USERNAME" \
  --policy-name "S3-${BUCKET_NAME}-access" \
  --policy-document "$POLICY_JSON"
success "IAM policy attached"

# Create access keys — written to file only, never echoed to terminal
info "Generating access keys (saving to file — not displayed)..."
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name "$USERNAME" --output json)

# Save credentials securely — chmod 600 so only owner can read
cat > "$CREDENTIALS_FILE" <<EOF
{
  "warning": "Keep this file secret. Do not commit to git or share with anyone.",
  "iam_username": "$USERNAME",
  "bucket": "$BUCKET_NAME",
  "region": "$REGION",
  "access_key_id": $(echo "$ACCESS_KEY_OUTPUT" | jq '.AccessKey.AccessKeyId'),
  "secret_access_key": $(echo "$ACCESS_KEY_OUTPUT" | jq '.AccessKey.SecretAccessKey'),
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
chmod 600 "$CREDENTIALS_FILE"
success "Access keys saved to $CREDENTIALS_FILE (readable by you only)"

# ── Step 3: Create CloudFront Origin Access Control ───────────────────────────
info "Creating CloudFront Origin Access Control (OAC)..."
OAC_CONFIG=$(cat <<EOF
{
  "Name": "oac-${BUCKET_NAME}",
  "Description": "OAC for S3 bucket ${BUCKET_NAME}",
  "SigningProtocol": "sigv4",
  "SigningBehavior": "always",
  "OriginAccessControlOriginType": "s3"
}
EOF
)

OAC_OUTPUT=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config "$OAC_CONFIG" \
  --output json)
OAC_ID=$(echo "$OAC_OUTPUT" | jq -r '.OriginAccessControl.Id')
success "OAC created: $OAC_ID"

# ── Step 4: Create CloudFront distribution ────────────────────────────────────
info "Creating CloudFront distribution (this may take a moment)..."

CALLER_REF="setup-${BUCKET_NAME}-$(date +%s)"
S3_DOMAIN="${BUCKET_NAME}.s3.${REGION}.amazonaws.com"

DIST_CONFIG=$(cat <<EOF
{
  "CallerReference": "${CALLER_REF}",
  "Comment": "CloudFront for ${BUCKET_NAME}",
  "Enabled": true,
  "HttpVersion": "http2and3",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-${BUCKET_NAME}",
        "DomainName": "${S3_DOMAIN}",
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        },
        "OriginAccessControlId": "${OAC_ID}"
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${BUCKET_NAME}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "Compress": true,
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    }
  },
  "PriceClass": "PriceClass_All"
}
EOF
)

DIST_OUTPUT=$(aws cloudfront create-distribution \
  --distribution-config "$DIST_CONFIG" \
  --output json)

DIST_ID=$(echo "$DIST_OUTPUT" | jq -r '.Distribution.Id')
DIST_ARN=$(echo "$DIST_OUTPUT" | jq -r '.Distribution.ARN')
DIST_DOMAIN=$(echo "$DIST_OUTPUT" | jq -r '.Distribution.DomainName')
success "CloudFront distribution created: $DIST_ID"
success "Domain: $DIST_DOMAIN"

# ── Step 5: Lock S3 bucket to CloudFront only ─────────────────────────────────
info "Updating S3 bucket policy — allowing CloudFront OAC only..."

BUCKET_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontOACReadOnly",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "${BUCKET_ARN}/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "${DIST_ARN}"
        }
      }
    }
  ]
}
EOF
)

aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy "$BUCKET_POLICY"
success "Bucket policy updated — direct S3 access blocked, CloudFront OAC is the only public reader"

# ── Step 6: Write summary file ────────────────────────────────────────────────
cat > "$SUMMARY_FILE" <<EOF
AWS Setup Summary
=================
Date:               $(date -u)
Account ID:         $ACCOUNT_ID

S3 Bucket
---------
Name:               $BUCKET_NAME
Region:             $REGION
ARN:                $BUCKET_ARN
Public Access:      BLOCKED
Encryption:         AES-256 (SSE-S3)
Direct URL:         https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com (blocked — CloudFront only)

CloudFront
----------
Distribution ID:    $DIST_ID
Domain:             https://$DIST_DOMAIN
OAC ID:             $OAC_ID
HTTPS:              Enforced (HTTP redirects to HTTPS)
Status:             Deploying (~15 minutes until live)

IAM User
--------
Username:           $USERNAME
Policy:             S3-${BUCKET_NAME}-access (scoped to this bucket only)
Credentials file:   $CREDENTIALS_FILE

Usage example (upload a file):
  aws s3 cp myfile.txt s3://${BUCKET_NAME}/myfile.txt \\
    --profile <your-profile>  OR  with credentials from $CREDENTIALS_FILE

Access via CloudFront:
  https://${DIST_DOMAIN}/myfile.txt
EOF

echo ""
echo "══════════════════════════════════════════════════════"
success "Setup complete!"
echo ""
echo "  CloudFront domain : https://$DIST_DOMAIN"
echo "  S3 bucket         : $BUCKET_NAME ($REGION)"
echo "  IAM user          : $USERNAME"
echo "  Credentials saved : $CREDENTIALS_FILE"
echo "  Full summary      : $SUMMARY_FILE"
echo ""
warn "CloudFront is deploying — it will be live in ~15 minutes."
warn "Keep $CREDENTIALS_FILE secret. Do not share or commit it to git."
echo "══════════════════════════════════════════════════════"
