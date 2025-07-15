#!/bin/bash
set -e

# Configuration
DEPLOY_URL="https://raw.githubusercontent.com/NeptuneHub/git-at-home/main/git-at-home-deployment.yaml"
OUT_FILE="git-at-home-deployment-with-secret.yaml"
KEY_NAME="git-at-home.key"
PUB_KEY="$KEY_NAME.pub"
NAMESPACE="git-at-home"

# 1️⃣ Download existing deployment YAML
echo "🔽 Downloading deployment YAML..."
curl -sL "$DEPLOY_URL" -o original-deployment.yaml

# 2️⃣ Generate SSH key pair
echo "🔐 Generating SSH keypair..."
ssh-keygen -t ed25519 -f "$KEY_NAME" -N "" -C "git-at-home"

# 3️⃣ Base64-encode the public key (no newlines)
ENC_KEY=$(base64 -w0 "$PUB_KEY")

# 4️⃣ Build Secret manifest
SECRET_YAML=$(cat <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: git-ssh-keys
  namespace: $NAMESPACE
type: Opaque
data:
  authorized_keys: |
    $ENC_KEY
EOF
)

# 5️⃣ Construct new deployment YAML with Secret inserted after Namespace block
echo "🧩 Injecting Secret into deployment manifest..."
awk -v secret="$SECRET_YAML" '
  BEGIN {namespace_seen=0}
  /^---/ {
    print
    next
  }
  /^apiVersion: v1/ && /kind: Namespace/ {
    namespace_seen=1
  }
  {
    print
    if(namespace_seen && NF==0) {
      print secret
      namespace_seen=0
    }
  }
' original-deployment.yaml > "$OUT_FILE"

echo "✅ Updated manifest saved to: $OUT_FILE"
echo "🔑 Private key: $KEY_NAME"
echo "📄 Public key: $PUB_KEY"
