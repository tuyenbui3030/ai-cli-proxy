# View Service Logs

View logs from the specified service.

Usage: /project:logs <service>

Services:
- api (cli-proxy-api)
- backup (cli-proxy-backup)
- restore (cli-proxy-restore)

Run: `docker logs --tail 50 -f <container_name>`

If no service specified, default to cli-proxy-api.
