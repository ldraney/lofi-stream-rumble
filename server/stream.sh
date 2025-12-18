#!/bin/bash
# Lofi Stream to Rumble
# Captures a headless browser playing our library lofi page and streams to Rumble

set -e

# Configuration
DISPLAY_NUM=96
SINK_NAME="rumble_speaker"
RESOLUTION="1280x720"
FPS=24
PAGE_URL="https://ldraney.github.io/lofi-stream-rumble/"

# Stream URL and key from environment
# Note: Rumble provides a user-specific RTMP URL
if [ -z "$RUMBLE_URL" ]; then
    echo "Error: RUMBLE_URL environment variable not set"
    echo "Get this from: rumble.com/live > Go Live > GET STREAMER CONFIGURATION"
    exit 1
fi

if [ -z "$RUMBLE_KEY" ]; then
    echo "Error: RUMBLE_KEY environment variable not set"
    echo "Get this from: rumble.com/live > Go Live > GET STREAMER CONFIGURATION"
    exit 1
fi

echo "Starting Lofi Stream to Rumble..."
echo "Resolution: $RESOLUTION @ ${FPS}fps"

# Cleanup any existing processes
cleanup() {
    echo "Cleaning up..."
    pkill -f "Xvfb :$DISPLAY_NUM" 2>/dev/null || true
    pkill -f "chromium.*lofi-stream-rumble" 2>/dev/null || true
    pkill -f "ffmpeg.*rumble" 2>/dev/null || true
}

trap cleanup EXIT
cleanup
sleep 2

# Start virtual display
echo "Starting virtual display :$DISPLAY_NUM..."
Xvfb :$DISPLAY_NUM -screen 0 ${RESOLUTION}x24 &
XVFB_PID=$!
sleep 2
export DISPLAY=:$DISPLAY_NUM

# PulseAudio setup (shared with other streams - don't start/stop)
echo "Setting up PulseAudio sink..."
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR

# Ensure PulseAudio is running
pulseaudio --check || pulseaudio --start --exit-idle-time=-1

# Create our own virtual audio sink
pactl load-module module-null-sink sink_name=$SINK_NAME sink_properties=device.description=RumbleSpeaker 2>/dev/null || true

# Export PULSE_SERVER for ffmpeg
export PULSE_SERVER=unix:$XDG_RUNTIME_DIR/pulse/native

# Start Chromium with separate user data dir
echo "Starting Chromium..."
chromium-browser \
    --no-sandbox \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-dev-shm-usage \
    --user-data-dir=/tmp/chromium-rumble \
    --kiosk \
    --autoplay-policy=no-user-gesture-required \
    --window-size=1280,720 \
    --window-position=0,0 \
    "$PAGE_URL" &
CHROME_PID=$!

# Wait for page to load
echo "Waiting for page to load..."
sleep 8

# Trigger audio with xdotool
echo "Triggering audio..."
xdotool mousemove 640 360 click 1
sleep 1
xdotool key space
sleep 1
xdotool mousemove 640 360 click 1
sleep 2

# Move THIS Chromium's audio to our rumble sink (find by PID)
sleep 1
SINK_INPUT=$(pactl list sink-inputs | grep -B 20 "application.process.id = \"$CHROME_PID\"" | grep "Sink Input" | grep -oP '#\K\d+' | tail -1)
if [ -n "$SINK_INPUT" ]; then
    pactl move-sink-input $SINK_INPUT $SINK_NAME
    echo "Moved Chromium (PID $CHROME_PID) to $SINK_NAME"
else
    echo "Warning: Could not find sink input for Chromium PID $CHROME_PID"
    # Fallback: try to move most recent sink input
    LATEST_INPUT=$(pactl list short sink-inputs | tail -1 | awk '{print $1}')
    [ -n "$LATEST_INPUT" ] && pactl move-sink-input $LATEST_INPUT $SINK_NAME 2>/dev/null || true
fi

# Start FFmpeg streaming to Rumble
echo "Starting FFmpeg stream to Rumble..."
PULSE_SERVER=unix:$XDG_RUNTIME_DIR/pulse/native ffmpeg \
    -thread_queue_size 1024 \
    -f x11grab \
    -video_size $RESOLUTION \
    -framerate $FPS \
    -draw_mouse 0 \
    -i :$DISPLAY_NUM \
    -thread_queue_size 1024 \
    -f pulse \
    -i ${SINK_NAME}.monitor \
    -c:v libx264 \
    -preset ultrafast \
    -tune zerolatency \
    -b:v 4500k \
    -maxrate 4500k \
    -bufsize 9000k \
    -pix_fmt yuv420p \
    -g 48 \
    -c:a aac \
    -b:a 128k \
    -ar 44100 \
    -flvflags no_duration_filesize \
    -f flv "${RUMBLE_URL}/${RUMBLE_KEY}"
