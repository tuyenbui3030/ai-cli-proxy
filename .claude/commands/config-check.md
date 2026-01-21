# Configuration Check

Validate the current configuration files.

Checks to perform:

1. **config.yaml exists**: Verify file exists and is valid YAML
2. **.env exists**: Verify file exists
3. **API_TOKEN set**: Check if API_TOKEN in .env is not empty
4. **api-keys configured**: Check if api-keys in config.yaml are not defaults
5. **Docker health**: Run `docker compose config` to validate docker-compose.yml

Report any issues found.
