#!/usr/bin/env bash
# tmux status module: CPU and memory load, as two pills from one job.
# Usage: sys.sh <surface> <cpu-accent> <mem-accent> <busy-accent>
set -u

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

surface="${1:-#363a4f}"
cpu_accent="${2:-#7dc4e4}"
mem_accent="${3:-#c6a0f6}"
busy="${4:-#f5a97f}"

cpu='' mem=''

case "$(uname -s)" in
	Darwin)
		ncpu="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
		# Summed per-process CPU share, normalised by core count. Instantaneous
		# CPU on macOS needs `top -l2`, which costs a second per sample.
		cpu="$(ps -A -o %cpu= 2>/dev/null | awk -v n="$ncpu" '
			{s += $1} END {v = s / n; if (v > 100) v = 100; printf "%.0f", v}')"
		mem="$(vm_stat 2>/dev/null | awk '
			/page size of/    {for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+$/) ps = $i}
			/Pages free/      {free = $3}
			/Pages active/    {active = $3}
			/Pages inactive/  {inactive = $3}
			/Pages speculative/ {spec = $3}
			/Pages wired down/ {wired = $4}
			/Pages occupied by compressor/ {comp = $5}
			END {
				gsub(/\./, "", free); gsub(/\./, "", active); gsub(/\./, "", inactive)
				gsub(/\./, "", spec); gsub(/\./, "", wired); gsub(/\./, "", comp)
				total = free + active + inactive + spec + wired + comp
				if (total > 0) printf "%.0f", (active + wired + comp) * 100 / total
			}')"
		;;
	Linux)
		ncpu="$(nproc 2>/dev/null || echo 1)"
		cpu="$(awk -v n="$ncpu" '{v = $1 * 100 / n; if (v > 100) v = 100; printf "%.0f", v; exit}' \
			/proc/loadavg 2>/dev/null)"
		mem="$(awk '
			/^MemTotal:/     {t = $2}
			/^MemAvailable:/ {a = $2}
			END {if (t > 0) printf "%.0f", (t - a) * 100 / t}' /proc/meminfo 2>/dev/null)"
		;;
esac

out=''
if [ -n "$cpu" ]; then
	accent="$cpu_accent"
	[ "$cpu" -ge 80 ] && accent="$busy"
	out+="$(pill "$surface" "$accent" "${ICO_CPU} ${cpu}%") "
fi
if [ -n "$mem" ]; then
	accent="$mem_accent"
	[ "$mem" -ge 90 ] && accent="$busy"
	out+="$(pill "$surface" "$accent" "${ICO_MEM} ${mem}%")"
fi

printf '%s' "$out"
