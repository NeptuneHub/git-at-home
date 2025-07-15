#!/bin/bash
set -e

# Configuration
DEPLOY_URL="https://raw.githubusercontent.com/NeptuneHub/git-at-home/main/git-at-home-deployment.yaml"
OUT_FILE="git-at-home-deployment-with-secret.yaml"
KEY_NAME="git-at-home.key"
PUB_KEY="$KEY_NAME.pub"
NAMESPACE="git-at-home"
TMP_FILE="original-deployment.yaml"

# 1️⃣ Download existing deployment YAML
echo "🔽 Downloading deployment YAML..."
curl -sL "$DEPLOY_URL" -o "$TMP_FILE"

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
  authorized_keys: "$ENC_KEY"
EOF
)

# 5️⃣ Inject Secret manifest directly below Namespace definition
echo "🧩 Injecting Secret into deployment manifest..."
awk -v secret="$SECRET_YAML" '
  BEGIN {inserted=0}
  {
    print
    if (!inserted && $0 ~ /^kind: Namespace$/) {
      getline; print
      print ""
      print secret
      inserted=1
    }
  }
' "$TMP_FILE" > "$OUT_FILE"

# 6️⃣ Cleanup
rm -f "$TMP_FILE"

echo "✅ DONE: Manifest with secret -> $OUT_FILE"
echo "🔑 SSH private key: $KEY_NAME"
echo "📄 SSH public key: $PUB_KEY"
