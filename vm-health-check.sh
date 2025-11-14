#!/bin/bash

THRESHOLD=60
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << EOF
VM Health Monitor - Analyze virtual machine health status

USAGE:
    ./vm-health-check.sh [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -r, --reason            Display detailed health analysis with reasons
    -t, --threshold VALUE   Set custom threshold percentage (default: 60)

EXAMPLES:
    ./vm-health-check.sh                    # Basic health status
    ./vm-health-check.sh --reason           # Detailed health analysis
    ./vm-health-check.sh -r -t 50           # Detailed analysis with 50% threshold

EOF
}

get_cpu_usage() {
    local cpu_usage

    if [ -f /proc/stat ]; then
        local start_idle start_total end_idle end_total

        read start_idle start_total <<< "$(awk '/^cpu / {idle=$5; sum=0; for(i=2; i<=NF; i++) sum+=$i; print idle, sum}' /proc/stat)"
        sleep 1
        read end_idle end_total <<< "$(awk '/^cpu / {idle=$5; sum=0; for(i=2; i<=NF; i++) sum+=$i; print idle, sum}' /proc/stat)"

        local diff_idle=$((end_idle - start_idle))
        local diff_total=$((end_total - start_total))
        cpu_usage=$((100 * (diff_total - diff_idle) / diff_total))
    else
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d'.' -f1)
    fi

    echo "$cpu_usage"
}

get_memory_usage() {
    local mem_usage

    if [ -f /proc/meminfo ]; then
        local total_mem available_mem
        total_mem=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
        available_mem=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
        mem_usage=$(( 100 * (total_mem - available_mem) / total_mem ))
    else
        mem_usage=$(free | grep Mem | awk '{printf("%.0f", 100 * $3 / $2)}')
    fi

    echo "$mem_usage"
}

get_disk_usage() {
    local disk_usage
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "$disk_usage"
}

determine_health_status() {
    local cpu=$1
    local memory=$2
    local disk=$3
    local threshold=$4

    if [ "$cpu" -lt "$threshold" ] && [ "$memory" -lt "$threshold" ] && [ "$disk" -lt "$threshold" ]; then
        echo "healthy"
    else
        echo "unhealthy"
    fi
}

display_basic_status() {
    local status=$1

    if [ "$status" = "healthy" ]; then
        echo -e "${GREEN}[✓] System Health: HEALTHY${NC}"
    else
        echo -e "${RED}[✗] System Health: UNHEALTHY${NC}"
    fi
}

display_detailed_analysis() {
    local cpu=$1
    local memory=$2
    local disk=$3
    local threshold=$4
    local status=$5

    echo ""
    echo "================================"
    echo "VM Health Analysis Report"
    echo "================================"
    echo "Timestamp: $TIMESTAMP"
    echo "Health Threshold: ${threshold}%"
    echo ""

    if [ "$status" = "healthy" ]; then
        echo -e "${GREEN}Overall Status: HEALTHY${NC}"
    else
        echo -e "${RED}Overall Status: UNHEALTHY${NC}"
    fi

    echo ""
    echo "Detailed Metrics:"
    echo "----------------"

    if [ "$cpu" -lt "$threshold" ]; then
        echo -e "  CPU Usage: ${GREEN}${cpu}%${NC} ✓ (Below threshold)"
    else
        echo -e "  CPU Usage: ${RED}${cpu}%${NC} ✗ (Exceeds threshold)"
    fi

    if [ "$memory" -lt "$threshold" ]; then
        echo -e "  Memory Usage: ${GREEN}${memory}%${NC} ✓ (Below threshold)"
    else
        echo -e "  Memory Usage: ${RED}${memory}%${NC} ✗ (Exceeds threshold)"
    fi

    if [ "$disk" -lt "$threshold" ]; then
        echo -e "  Disk Usage: ${GREEN}${disk}%${NC} ✓ (Below threshold)"
    else
        echo -e "  Disk Usage: ${RED}${disk}%${NC} ✗ (Exceeds threshold)"
    fi

    echo ""
    echo "Reasons:"
    echo "--------"

    if [ "$cpu" -ge "$threshold" ]; then
        echo "  • CPU usage is at ${cpu}%, which exceeds the ${threshold}% threshold"
    fi

    if [ "$memory" -ge "$threshold" ]; then
        echo "  • Memory usage is at ${memory}%, which exceeds the ${threshold}% threshold"
    fi

    if [ "$disk" -ge "$threshold" ]; then
        echo "  • Disk usage is at ${disk}%, which exceeds the ${threshold}% threshold"
    fi

    if [ "$status" = "healthy" ]; then
        echo "  • All system resources are within acceptable limits"
    fi

    echo ""
    echo "================================"
}

main() {
    local show_reason=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -r|--reason)
                show_reason=true
                shift
                ;;
            -t|--threshold)
                if [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null; then
                    THRESHOLD=$2
                    shift 2
                else
                    echo "Error: --threshold requires a numeric value"
                    exit 1
                fi
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    echo "Analyzing system health..."

    local cpu_usage
    local memory_usage
    local disk_usage

    cpu_usage=$(get_cpu_usage)
    memory_usage=$(get_memory_usage)
    disk_usage=$(get_disk_usage)

    local health_status
    health_status=$(determine_health_status "$cpu_usage" "$memory_usage" "$disk_usage" "$THRESHOLD")

    if [ "$show_reason" = true ]; then
        display_detailed_analysis "$cpu_usage" "$memory_usage" "$disk_usage" "$THRESHOLD" "$health_status"
    else
        display_basic_status "$health_status"
    fi
}

main "$@"
