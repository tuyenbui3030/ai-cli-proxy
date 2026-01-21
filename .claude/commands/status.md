# Check Service Status

Check the current status of all Docker services in this project.

Run the following commands and report the results:

1. `docker compose ps` - Show running containers
2. `docker logs --tail 20 cli-proxy-api` - Recent API logs
3. `docker logs --tail 10 cli-proxy-backup` - Recent backup logs
4. Check if `backups/usage-latest.json` exists and show its timestamp

Summarize the health status of each service.
