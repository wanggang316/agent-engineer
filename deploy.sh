#!/usr/bin/env bash
# Build and deploy the Agent Engineer docs site to local Docker.
#
# Usage:
#   ./deploy.sh              # build + (re)start, foreground logs
#   ./deploy.sh up           # build + start in background
#   ./deploy.sh down         # stop and remove container
#   ./deploy.sh logs         # tail container logs
#   ./deploy.sh rebuild      # force no-cache rebuild then up
#   ./deploy.sh status       # show container + healthcheck state
#
# Env:
#   HOST_PORT   port on host (default 8080)

set -euo pipefail

cd "$(dirname "$0")"

HOST_PORT="${HOST_PORT:-8080}"
export HOST_PORT

cmd="${1:-up}"

case "$cmd" in
  up)
    docker compose up -d --build
    docker compose ps
    echo
    echo "→ http://localhost:${HOST_PORT}/        (English)"
    echo "→ http://localhost:${HOST_PORT}/zh-cn/  (中文)"
    ;;
  down)
    docker compose down
    ;;
  logs)
    docker compose logs -f --tail=100
    ;;
  rebuild)
    docker compose build --no-cache
    docker compose up -d
    docker compose ps
    ;;
  status)
    docker compose ps
    docker inspect --format='{{.State.Health.Status}}' agent-engineer-docs 2>/dev/null \
      | sed 's/^/health: /' || true
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    echo "Run: $0 {up|down|logs|rebuild|status}" >&2
    exit 2
    ;;
esac
