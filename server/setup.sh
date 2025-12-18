#!/bin/bash
# Setup script for lofi-stream-rumble on VPS

set -e

echo "Setting up lofi-stream-rumble..."

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y xvfb chromium-browser ffmpeg pulseaudio xdotool curl jq

# Create directory
echo "Creating /opt/lofi-stream-rumble..."
mkdir -p /opt/lofi-stream-rumble

# Copy scripts
echo "Copying scripts..."
cp stream.sh /opt/lofi-stream-rumble/
cp health-check.sh /opt/lofi-stream-rumble/
chmod +x /opt/lofi-stream-rumble/*.sh

# Install systemd service
echo "Installing systemd service..."
cp lofi-stream-rumble.service /etc/systemd/system/
systemctl daemon-reload

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit /etc/systemd/system/lofi-stream-rumble.service"
echo "   Set: Environment=RUMBLE_URL=your_rtmp_url"
echo "   Set: Environment=RUMBLE_KEY=your_stream_key"
echo ""
echo "2. Get your Rumble stream credentials:"
echo "   a. Go to https://rumble.com/live"
echo "   b. Click 'Go Live' to create a stream"
echo "   c. Click 'GET STREAMER CONFIGURATION'"
echo "   d. Copy the Stream URL and Stream Key"
echo ""
echo "   IMPORTANT: Enable 'Static Stream Key' in Rumble settings"
echo "   for 24/7 streaming (so key doesn't expire)"
echo ""
echo "   Requirements: 5 followers, phone verification"
echo ""
echo "3. Enable and start the service:"
echo "   systemctl enable lofi-stream-rumble"
echo "   systemctl start lofi-stream-rumble"
echo ""
echo "4. Check status:"
echo "   systemctl status lofi-stream-rumble"
echo "   journalctl -u lofi-stream-rumble -f"
