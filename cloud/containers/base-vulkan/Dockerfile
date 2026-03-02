# Base Image for AI Cloud Gaming (Deep Infrastructure Pillar 1)
# Uses NVIDIA CUDA + Vulkan for high-fidelity 3D rendering
FROM nvidia/cuda:12.2.0-base-ubuntu22.04

# 1. Install System Dependencies & GPU Drivers Support
RUN apt-get update && apt-get install -y \
    vulkan-tools \
    libvulkan1 \
    libnvidia-gl-535 \
    libx11-6 \
    x11-xserver-utils \
    xvfb \
    ffmpeg \
    webrtc-audio-processing-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Install High-Performance Streaming Encoder (OvenMediaEngine/WebRTC)
# This simulates the "Ultra-Low Latency Streaming Engine" pillar
# In production, this would be a custom build of WebRTC / CloudXR
ENV STREAMING_ENCODER_VERSION=1.0.0
RUN mkdir -p /opt/streaming-engine
COPY ./streaming_core /opt/streaming-engine/

# 3. Add Input Forwarding System (Mouse/Keyboard/Touch -> Game)
# Custom listener that translates JSON input packets to localized system calls
RUN mkdir -p /opt/input-bridge
COPY ./input_bridge /opt/input-bridge/

# 4. Lock down OS access (Pillar 1 Secure Environment)
RUN useradd -m cloudgamer
USER cloudgamer
WORKDIR /home/cloudgamer

# Default environment for Cloud Gaming
ENV DISPLAY=:0
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute,display

LABEL version="0.1.0-alpha"
LABEL description="Base AI Cloud Gaming Image with NVIDIA GPU Support & WebRTC"
