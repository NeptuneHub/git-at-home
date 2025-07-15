#!/bin/bash
set -e

# --- Configuration ---
# URL of the base Kubernetes deployment YAML
DEPLOY_URL="https://raw.githubusercontent.com/NeptuneHub/git-at-home/main/git-at-home-deployment.yaml"

# Namespace where resources will be deployed
NAMESPACE="git-at-home"

# Temporary file names
TMP_SECRET_FILE="secret.yaml"
TMP_FULL_DEPLOYMENT="full-deployment.yaml"

# Output file name for the final combined YAML
OUT_FILE="git-at-home-deployment-with-secret.yaml"

# SSH key file names
KEY_NAME="git-at-home.key"
PUB_KEY="$KEY_NAME.pub"


# --- Script ---

# 1. Generate a new SSH key pair
echo "🔐 Generating SSH key pair ($KEY_NAME and $PUB_KEY)..."
# -t ed25519: modern and secure key type
# -f "$KEY_NAME": specifies the output file for the private key
# -N "": specifies an empty passphrase
# -C "git-at-home": adds a comment to the public key
ssh-keygen -t ed25519 -f "$KEY_NAME" -N "" -C "git-at-home"
echo "✅ SSH key pair generated."
echo

# 2. Download the deployment YAML and split it into separate files
echo "⬇️  Downloading and processing the base deployment YAML..."
curl -sL "$DEPLOY_URL" -o "$TMP_FULL_DEPLOYMENT"

# Use awk to reliably split the multi-document YAML into individual files.
# This command splits the input file by '---' and creates doc-1.yaml, doc-2.yaml, etc.
# Each file will contain one resource definition, without the '---' separator.
awk 'BEGIN {c=0} /^---/ {c++} {if (c > 0) print > "doc-" c ".yaml"}' "$TMP_FULL_DEPLOYMENT"

# The original file has 3 documents: Namespace, Deployment, Service.
# They will be split into doc-1.yaml, doc-2.yaml, and doc-3.yaml.
echo "✅ Base YAML processed and split into individual documents."
echo

# 3. Create the Kubernetes Secret YAML for the public key
echo "📝 Creating Kubernetes Secret manifest..."
# The public key must be base64 encoded to be placed in a Secret's data field.
# The -A flag ensures the output is a single, unbroken line of text.
ENCODED_KEY=$(openssl base64 -A -in "$PUB_KEY")

# Use a heredoc to create the Secret manifest content.
# Note: We do not add '---' here; it will be added during assembly.
cat > "$TMP_SECRET_FILE" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: git-ssh-keys
  namespace: $NAMESPACE
type: Opaque
data:
  # The key name 'authorized_keys' must match the 'subPath' in the Deployment's volumeMount.
  authorized_keys: $ENCODED_KEY
EOF
echo "✅ Secret manifest created."
echo

# 4. Combine all the YAML parts into a single, valid output file
echo "📦 Assembling the final deployment file in the correct order..."
# Start with a clean file for the output.
rm -f "$OUT_FILE"

# The correct order for kubectl is: Namespace, then dependent resources like Secrets, then Deployments/Services.
# We add '---' before each document to ensure the final file is a valid multi-document YAML.
echo "---" >> "$OUT_FILE"
cat doc-1.yaml >> "$OUT_FILE" # Document 1: Namespace

echo "---" >> "$OUT_FILE"
cat "$TMP_SECRET_FILE" >> "$OUT_FILE" # Our new Secret

echo "---" >> "$OUT_FILE"
cat doc-2.yaml >> "$OUT_FILE" # Document 2: Deployment

echo "---" >> "$OUT_FILE"
cat doc-3.yaml >> "$OUT_FILE" # Document 3: Service

echo "✅ Final deployment file created: $OUT_FILE"
echo

# 5. Clean up temporary files
echo "🧹 Cleaning up temporary files..."
rm -f "$TMP_SECRET_FILE" "$TMP_FULL_DEPLOYMENT" doc-*.yaml
echo "✅ Cleanup complete."
echo

# 6. Final instructions
echo "🎉 All done!"
echo
echo "The generated file '$OUT_FILE' is now correctly formatted."
echo "You can deploy everything using kubectl:"
echo "kubectl apply -f $OUT_FILE"
echo
echo "IMPORTANT:"
echo "🔑 Your private key is in the file: '$KEY_NAME'"
echo "   Keep this file safe and secure. You will need it to connect to your Git server."
echo
echo "📄 Your public key is in the file: '$PUB_KEY'"
