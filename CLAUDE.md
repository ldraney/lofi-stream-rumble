# lofi-stream-rumble

24/7 lofi stream to Rumble with a cozy library/study theme.

## Quick Reference

```bash
# Local development - open in browser
cd docs && python3 -m http.server 8080

# Deploy to dev server for testing
make deploy-dev

# Check production status
ssh root@135.181.150.82 'systemctl status lofi-stream-rumble'
```

## Architecture

```
GitHub Pages (static HTML/CSS/JS)
        ↓ (rendered by)
Chromium on Hetzner VPS (:96)
        ↓ (captured by)
FFmpeg → RTMP → Rumble
```

## Theme: Library Study

Visual elements:
- Dark wood paneling background
- Large bookshelf with varied leather/cloth book spines
- Leather armchair with reading lamp (warm glow)
- Desk with open book, fountain pen, inkwell
- Window with rain and soft ambient light
- Small fireplace with flickering flames
- Decorations: globe, candle, pocket watch

Color palette:
- Deep brown: #3d2817
- Mahogany: #2a1a0f
- Burgundy: #722f37
- Forest green: #2d4a3e
- Gold accent: #c9a227
- Cream: #f5f0e1

## Audio: Classical-Inspired Lofi

- Soft piano-like tones (sine + slight detune for warmth)
- Chord progression: Dm → Gm → C → F (contemplative minor feel)
- Very soft strings pad with slow attack
- Gentle double-bass style bass
- Ambient: fire crackle, rain on window, clock ticking, page turns
- Enhanced vinyl crackle for vintage feel

## Server Configuration

| Setting | Value |
|---------|-------|
| Display | :96 |
| Audio Sink | rumble_speaker |
| User Data Dir | /tmp/chromium-rumble |
| RTMP URL | User-specific from Rumble dashboard |
| Video Bitrate | 4500 kbps |
| Audio Bitrate | 128 kbps |
| Resolution | 1280x720 @ 24fps |

## File Structure

```
lofi-stream-rumble/
├── CLAUDE.md           # This file
├── README.md           # Public readme
├── Makefile            # Dev server deployment
├── docs/
│   ├── index.html      # Library visuals + Web Audio
│   └── style.css       # Warm wood/leather styling
└── server/
    ├── stream.sh       # Main streaming script
    ├── setup.sh        # Server setup automation
    ├── health-check.sh # Monitoring script
    └── lofi-stream-rumble.service # systemd unit
```

## Deployment

### First-time setup on production server:

```bash
# On VPS (135.181.150.82)
cd /opt
git clone https://github.com/ldraney/lofi-stream-rumble.git
cd lofi-stream-rumble/server
chmod +x *.sh
./setup.sh

# Edit service file to add stream key and URL
sudo nano /etc/systemd/system/lofi-stream-rumble.service
# Change: Environment=RUMBLE_URL=your_rtmp_url
# Change: Environment=RUMBLE_KEY=your_stream_key

# Start the service
sudo systemctl daemon-reload
sudo systemctl enable lofi-stream-rumble
sudo systemctl start lofi-stream-rumble
```

### Get Rumble Stream Key:

1. Go to https://rumble.com/live
2. Click "Go Live" to create a new stream
3. Click "GET STREAMER CONFIGURATION"
4. Copy the Stream URL and Stream Key
5. **Important**: Set up "Static Stream Key" for 24/7 streaming

### Rumble Requirements:
- 5 followers minimum
- Phone verification
- Static stream key enabled (so key doesn't expire)

## Troubleshooting

### No audio in stream
- Check if PulseAudio sink exists: `pactl list sinks | grep rumble`
- Verify Chromium audio routing: `pactl list sink-inputs`
- Ensure PULSE_SERVER is exported in stream.sh

### Stream not connecting
- Verify RTMP URL is correct (user-specific)
- Check if stream key has expired (use Static Key)
- Verify account has 5+ followers and phone verification

### Video quality issues
- Check CPU usage: `htop`
- Can increase bitrate up to 6000k if needed
- Verify ffmpeg is using hardware acceleration if available

## Related Repos

- [lofi-stream-youtube](https://github.com/ldraney/lofi-stream-youtube) - Night city theme
- [lofi-stream-twitch](https://github.com/ldraney/lofi-stream-twitch) - Coffee shop theme
- [lofi-stream-kick](https://github.com/ldraney/lofi-stream-kick) - Arcade theme
- [lofi-stream-docs](https://github.com/ldraney/lofi-stream-docs) - Documentation hub
