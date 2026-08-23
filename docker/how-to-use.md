# Rebuild and push ONLY the web service after UI modifications:
.\scripts\push-docker.ps1 -Service web -Registry myregistry.com/myorg

# Rebuild and push ONLY the backend API service:
.\scripts\push-docker.ps1 -Service api -Registry myregistry.com/myorg

# Rebuild, push, and immediately update live running containers without touching PostgreSQL or volumes:
.\scripts\push-docker.ps1 -Service api -Registry myregistry.com/myorg -Deploy
