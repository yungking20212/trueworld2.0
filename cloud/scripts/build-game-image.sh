#!/bin/bash
# AI Cloud Gaming: Game Cloud Container Build Script (Pillar 1)

GAME_ID=$1
BUILD_TARGET=$2 # linux-vulkan / windows-dx11 (requires intermediate layer)

if [ -z "$GAME_ID" ]; then
  echo "Usage: ./build-game-image.sh <game_id> <target>"
  exit 1
fi

echo "🚀 Starting Cloud Container Build for Game: $GAME_ID"
echo "🛠 Target: $BUILD_TARGET"

# 1. Fetching Game Build Artifacts
echo "📦 Pulling build artifacts for $GAME_ID..."
mkdir -p ./tmp_build
# Simulate build pull
sleep 1

# 2. Layering Game onto Base Image
echo "🐳 Generating game-specific Dockerfile..."
cat <<EOF > ./containers/game-images/$GAME_ID.Dockerfile
FROM trueworld/base-vulkan:latest

# Install Game Build
COPY ./tmp_build/$GAME_ID /opt/game/
RUN chmod +x /opt/game/launch_binary

# Add Input Forwarding config
COPY ./metadata/$GAME_ID_input.json /opt/input-bridge/config.json

# Launch Command
ENTRYPOINT ["/opt/input-bridge/entrypoint.sh", "/opt/game/launch_binary"]
EOF

echo "✅ Container manifest generated for $GAME_ID"
echo "🔍 Ready for Docker Build: docker build -t trueworld-cloud-$GAME_ID -f ./containers/game-images/$GAME_ID.Dockerfile ."

rm -rf ./tmp_build
