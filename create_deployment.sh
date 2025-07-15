#!/bin/bash
set -e

# --- Configuration ---
# URL of the base Kubernetes deployment YAML
DEPLOY_URL="https://raw.githubusercontent.com/NeptuneHub/git-at-home/main/git-at-home-deployment.yaml"

# Namespace where resources will be deployed
NAMESPACE="git-at-home"

# Temporary file names
TMP_NS_FILE="namespace.yaml"
TMP_BODY_FILE="deployment-body.yaml"
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

# 2. Download the deployment YAML and split it into parts
echo "⬇️  Downloading and processing the base deployment YAML..."
curl -sL "$DEPLOY_URL" -o "$TMP_FULL_DEPLOYMENT"

# Split the YAML by the '---' separator. This creates multiple files: split00, split01, etc.
csplit --quiet --prefix=split "$TMP_FULL_DEPLOYMENT" "/^---/" "{*}"

# The first part (split00) is the Namespace definition. We move it.
mv split00 "$TMP_NS_FILE"

# The rest of the parts (split01, split02, ...) are concatenated into the body file.
# This is the key fix: the original script only used split01, which lost the Service definition.
cat split* > "$TMP_BODY_FILE"
echo "✅ Base YAML processed."
echo

# 3. Create the Kubernetes Secret YAML for the public key
echo "📝 Creating Kubernetes Secret manifest..."
# The public key must be base64 encoded to be placed in a Secret's data field.
# The -A flag ensures the output is a single, unbroken line of text.
ENCODED_KEY=$(openssl base64 -A -in "$PUB_KEY")

# Use a heredoc to create the Secret manifest.
cat > "$TMP_SECRET_FILE" <<EOF
---
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

# 4. Combine all the YAML parts into a single output file
echo "📦 Assembling the final deployment file..."
cat "$TMP_NS_FILE" "$TMP_SECRET_FILE" "$TMP_BODY_FILE" > "$OUT_FILE"
echo "✅ Final deployment file created: $OUT_FILE"
echo

# 5. Clean up temporary files
echo "🧹 Cleaning up temporary files..."
rm -f "$TMP_NS_FILE" "$TMP_BODY_FILE" "$TMP_SECRET_FILE" "$TMP_FULL_DEPLOYMENT" split*
echo "✅ Cleanup complete."
echo

# 6. Final instructions
echo "🎉 All done!"
echo
echo "You can now deploy everything using kubectl:"
echo "kubectl apply -f $OUT_FILE"
echo
echo "IMPORTANT:"
echo "🔑 Your private key is in the file: '$KEY_NAME'"
echo "   Keep this file safe and secure. You will need it to connect to your Git server."
echo
echo "📄 Your public key is in the file: '$PUB_KEY'"
