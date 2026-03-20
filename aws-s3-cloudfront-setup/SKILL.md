---
name: aws-s3-cloudfront-setup
description: >
  Set up a secure AWS infrastructure stack: S3 bucket (locked down, no public access), IAM user
  with least-privilege access keys saved locally, and CloudFront distribution using Origin Access
  Control (OAC). Use this skill whenever the user wants to create a new S3 bucket with CloudFront,
  set up an AWS CDN for file storage, create an IAM user scoped to a specific bucket, provision
  AWS storage infrastructure, or says things like "set up S3 with CloudFront", "create an S3 bucket
  and IAM user", "AWS file storage setup", or "s3 bucket cloudfront". Always trigger for any request
  involving creating AWS S3 + CloudFront together, even if phrased casually.
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# AWS S3 + CloudFront + IAM Setup Skill

Provisions a secure, production-ready AWS storage stack:
- **S3 bucket** — private, encrypted, no public access
- **CloudFront distribution** — only way to read files publicly, HTTPS-only, using OAC (modern, not deprecated OAI)
- **IAM user** — scoped to this bucket only (upload/download/delete), access keys saved to a local file

## Step 0 — Check prerequisites

Before anything else, verify AWS CLI is installed and credentials are configured.

### Check AWS CLI
Run: `aws --version`

If the command fails (not found), guide the user to install it:
- **macOS**: `brew install awscli` (requires Homebrew) or direct download from https://aws.amazon.com/cli/
- **Linux**: `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && unzip awscliv2.zip && sudo ./aws/install`
- **Windows**: Download the MSI installer from the AWS CLI page

After install, re-run `aws --version` to confirm.

### Check AWS credentials
Run: `aws sts get-caller-identity`

If it fails with "Unable to locate credentials" or similar, the user needs to configure their credentials. Guide them through this carefully:

1. They need an existing AWS account and an IAM user (or root user) with sufficient permissions
2. Run `aws configure` — it will prompt for:
   - **AWS Access Key ID** — from their AWS Console (IAM → Users → Security credentials → Create access key)
   - **AWS Secret Access Key** — shown only once when creating the key
   - **Default region** — e.g., `ap-southeast-1` for Singapore, `us-east-1` for US East
   - **Default output format** — enter `json`

**Security reminders to share with the user before they enter credentials:**
- Credentials are stored locally in `~/.aws/credentials` — this file stays on their machine only
- Never paste credentials into chat, email, or any online tool
- The `aws configure` command only writes to local config files, nothing is sent anywhere else
- The AWS key used to run this setup script needs permissions for S3, IAM, and CloudFront

Once `aws sts get-caller-identity` returns successfully (shows Account ID, UserId, Arn), proceed.

---

## Step 1 — Gather inputs

Ask the user for these three things (can be asked all at once):

1. **S3 bucket name** — must be globally unique, lowercase, no spaces (e.g., `my-project-assets-2024`)
2. **AWS region** — where to create the bucket (e.g., `ap-southeast-1`, `us-east-1`, `eu-west-1`)
3. **IAM username** — a name for the new IAM user (e.g., `my-project-s3-user`)

Validate before proceeding:
- Bucket name: 3–63 chars, lowercase letters/numbers/hyphens only, no dots (dots cause TLS issues with OAC)
- Region: must be a valid AWS region identifier
- Username: 1–64 chars, alphanumeric and `+=,.@-_` only

---

## Step 2 — Run the setup script

Once inputs are confirmed, run the setup script:

```bash
bash /Users/nongtm/.claude/skills/aws-s3-cloudfront-setup/scripts/setup.sh \
  --bucket "BUCKET_NAME" \
  --region "REGION" \
  --username "IAM_USERNAME"
```

Replace BUCKET_NAME, REGION, and IAM_USERNAME with the user's inputs.

The script will print progress as it runs. Watch for errors — if any step fails, the script exits with a clear message explaining what went wrong and how to fix it.

**The script takes 1–3 minutes to complete.** CloudFront deployment itself takes 10–15 minutes after that, but the script doesn't wait for it — it exits as soon as the distribution is created.

---

## Step 3 — Read and present the results

After the script finishes successfully, it creates two output files:

1. **`~/aws-setup-<BUCKET_NAME>/credentials.json`** — IAM access keys (sensitive!)
2. **`~/aws-setup-<BUCKET_NAME>/summary.txt`** — CloudFront domain, bucket name, distribution ID

Read both files and present the summary to the user. Show:
- CloudFront domain (e.g., `d1abc123xyz.cloudfront.net`)
- S3 bucket name and region
- IAM username and that credentials are saved to the file path

Tell the user:
- Files are accessible at `~/aws-setup-<BUCKET_NAME>/` in their home directory
- `credentials.json` contains their AWS access key — keep it safe, do not commit to git, do not share it
- CloudFront will be active in ~15 minutes (propagation time)
- To upload files, they use the IAM credentials with any S3-compatible tool or SDK

---

## Security notes (share with user at the end)

- The IAM user has **no console access** — only programmatic API access
- The IAM policy is scoped to **this specific bucket only** — they cannot touch other AWS resources
- S3 bucket has **no public access** — files are only accessible via the CloudFront URL
- CloudFront uses **OAC (Origin Access Control)** — the modern, sigv4-signed approach (not the deprecated OAI)
- Access keys are saved only to their **local filesystem** — they were never transmitted anywhere
- To revoke access: delete the IAM user or deactivate the access key in the AWS Console
