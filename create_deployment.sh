#!/bin/bash
set -e

# Config
DEPLOY_URL="https://raw.githubusercontent.com/NeptuneHub/git-at-home/main/git-at-home-deployment.yaml"
TMP_NS_FILE="ns.yaml"
TMP_BODY_FILE="rest.yaml"
OUT_FILE="git-at-home-deployment-with-secret.yaml"
KEY_NAME="git-at-home.key"
PUB_KEY="$KEY_NAME.pub"
NAMESPACE="git-at-home"

# 1. Generate SSH key
echo "🔐 Generating SSH key..."
ssh-keygen -t ed25519 -f "$KEY_NAME" -N "" -C "git-at-home"

# 2. Download deployment and split Namespace from the rest
echo "⬇️ Downloading deployment..."
curl -sL "$DEPLOY_URL" -o full.yaml

csplit --quiet --prefix=split full.yaml "/^---/" "{*}"
mv split00 "$TMP_NS_FILE"
cat split01 > "$TMP_BODY_FILE"
rm -f full.yaml

# 3. Encode public key safely
ENCODED_KEY=$(openssl base64 -A -in "$PUB_KEY")

# 4. Create the secret YAML block
cat > secret.yaml <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: git-ssh-keys
  namespace: $NAMESPACE
type: Opaque
data:
  authorized_keys: "$ENCODED_KEY"
EOF

# 5. Join all parts
cat "$TMP_NS_FILE" secret.yaml "$TMP_BODY_FILE" > "$OUT_FILE"

# 6. Clean up
rm -f "$TMP_NS_FILE" "$TMP_BODY_FILE" secret.yaml

# 7. Done
echo "✅ Deployment with secret ready: $OUT_FILE"
echo "🔑 Private key: $KEY_NAME"
echo "📄 Public key: $PUB_KEY"
