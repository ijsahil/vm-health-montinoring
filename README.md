# VM Health Monitor

A lightweight shell script for monitoring Ubuntu VM health by tracking CPU, memory, and disk usage.

## Features

- Real-time CPU usage monitoring
- Memory consumption tracking
- Disk space analysis
- Customizable health threshold (default: 60%)
- Detailed analysis with color-coded output
- Built-in help documentation

## Usage

### Basic Health Check
```bash
./vm-health-check.sh
```

### Detailed Analysis with Reasons
```bash
./vm-health-check.sh --reason
```

### Custom Threshold
```bash
./vm-health-check.sh -r -t 50
```

### Help
```bash
./vm-health-check.sh --help
```

## Options

- `-h, --help` - Show help message
- `-r, --reason` - Display detailed health analysis with reasons
- `-t, --threshold VALUE` - Set custom threshold percentage (default: 60)

## Requirements

- Ubuntu/Debian Linux system
- Bash shell
- Standard Linux utilities (awk, top, df, free)

## Output

The script returns:
- **HEALTHY** - All metrics are below the threshold
- **UNHEALTHY** - One or more metrics exceed the threshold

Color-coded output helps quickly identify issues:
- Green (✓) - Metric is within acceptable limits
- Red (✗) - Metric exceeds threshold
