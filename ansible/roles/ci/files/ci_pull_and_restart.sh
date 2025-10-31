#!/usr/bin/env bash
set -euo pipefail

# Source deployed env file if present
if [ -f /etc/ci_deploy.env ]; then
	# shellcheck source=/etc/ci_deploy.env
	# shellcheck disable=SC1091
	. /etc/ci_deploy.env
fi

# Registry and image names (can be overridden by env vars or /etc/ci_deploy.env)
REGISTRY="${REGISTRY:-ghcr.io/${USER}}"
BACKEND_IMAGE="${BACKEND_IMAGE:-${REGISTRY}/diagnostic_backend:latest}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-${REGISTRY}/diagnostic_frontend:latest}"

# Remote deploy options (optional)
DEPLOY_HOSTS="${DEPLOY_HOSTS:-}" 
# Default to devops user unless explicitly set
SSH_USER="${SSH_USER:-devops}"
# Allow SSH_KEY to be provided via env; if empty probe common devops key paths
SSH_KEY="${SSH_KEY:-}"

# Probe for common devops private key locations if SSH_KEY not supplied
if [ -z "${SSH_KEY:-}" ]; then
	for candidate in "/home/devops/.ssh/id_devops" "/home/devops/.ssh/id_rsa" "/home/devops/.ssh/id_ed25519" "/root/.ssh/id_rsa"; do
		if [ -f "$candidate" ]; then
			SSH_KEY="$candidate"
			break
		fi
	done
fi

if [ -n "${SSH_KEY:-}" ]; then
	echo "Using SSH key: ${SSH_KEY} (ensure this file is only readable by the runner)"
else
	echo "No SSH key supplied or discovered. SSH will run without -i and rely on agent/other auth." >&2
fi

retry_cmd() {
	# retry command up to $1 times (default 3) with delay $2 (default 2)
	local attempts=${1:-3}
	local delay=${2:-2}
	shift 2 || true
	local cmd=("$@")
	local i=1
	until "${cmd[@]}"; do
		if [ "$i" -ge "$attempts" ]; then
			echo "Command failed after $i attempts: ${cmd[*]}" >&2
			return 1
		fi
		echo "Command failed - retry $i/$attempts in ${delay}s: ${cmd[*]}" >&2
		sleep "$delay"
		i=$((i+1))
	done
}

local_deploy() {
	echo "[local] Pulling latest images..."
	retry_cmd 3 2 docker pull "$BACKEND_IMAGE" || true
	retry_cmd 3 2 docker pull "$FRONTEND_IMAGE" || true

	echo "[local] Stopping existing containers (if any)"
	docker rm -f diagnostic_backend || true
	docker rm -f diagnostic_frontend || true

	echo "[local] Starting containers..."
	docker run -d --name diagnostic_backend -p 5000:5000 --restart=always "$BACKEND_IMAGE"
	docker run -d --name diagnostic_frontend -p 3000:3000 --restart=always -e BACKEND_URL="http://127.0.0.1:5000/metrics" "$FRONTEND_IMAGE"

	echo "[local] Containers restarted successfully."
}

remote_deploy_host() {
	local host="$1"
	echo "[remote:$host] Deploying images..."
	local ssh_opts=( -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o BatchMode=yes )
	if [ -n "${SSH_KEY:-}" ] && [ -f "$SSH_KEY" ]; then
		ssh_opts+=( -i "$SSH_KEY" )
	fi

	# Build remote command script
	local remote_script
	remote_script=$(cat <<'EOF'
set -e
for i in 1 2 3; do docker pull "${BACKEND_IMAGE}" && break || sleep 2; done || true
for i in 1 2 3; do docker pull "${FRONTEND_IMAGE}" && break || sleep 2; done || true
docker rm -f diagnostic_backend || true
docker rm -f diagnostic_frontend || true
docker run -d --name diagnostic_backend -p 5000:5000 --restart=always "${BACKEND_IMAGE}"
docker run -d --name diagnostic_frontend -p 3000:3000 --restart=always -e BACKEND_URL="http://127.0.0.1:5000/metrics" "${FRONTEND_IMAGE}"
EOF
)

	# Use SSH to execute remote_script. Export image vars so remote shell can expand them.
	ssh "${ssh_opts[@]}" "${SSH_USER}@${host}" "BACKEND_IMAGE='${BACKEND_IMAGE}' FRONTEND_IMAGE='${FRONTEND_IMAGE}' bash -s" <<"REMOTE"
${remote_script}
REMOTE

	echo "[remote:$host] Deploy finished."
}

# Main
if [ -n "${DEPLOY_HOSTS}" ]; then
	IFS=',' read -ra hosts <<< "${DEPLOY_HOSTS}"
	for h in "${hosts[@]}"; do
		h_trimmed="$(echo "$h" | xargs)"
		if [ -n "$h_trimmed" ]; then
			remote_deploy_host "$h_trimmed"
		fi
	done
else
	local_deploy
fi

exit 0