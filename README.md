# Build from Dockerfile in current directory
docker build -t <image-name>:<tag> .

# Run with port mapping
docker run -p <host-port>:<container-port> <image-name>:<tag>

docker ps                # List running containers
docker ps -a             # List all containers (including stopped)
docker images            # List all local images

# Push Image to Docker Hub
docker login  # First time only

# Tag local image for Docker Hub
docker tag <local-image> <dockerhub-username>/<repo-name>:<tag>

# Example
docker tag my-node-api:dev scylla23/my-node-api:latest

# Push to Docker Hub
docker push <dockerhub-username>/<repo-name>:<tag>
docker push scylla23/my-node-app:latest
