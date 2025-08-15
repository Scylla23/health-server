End-to-End CI/CD Pipeline for a Node.js ApplicationThis document summarizes the process of containerizing a Node.js/PostgreSQL app, setting up Docker Compose, and building a full CI/CD pipeline with GitHub Actions for automated deployment to AWS.1. Local Containerization (Day 1) 📦First, we packaged the Node.js application into a portable Docker image.The DockerfileA multi-stage Dockerfile creates a small production image by separating the build and runtime environments.

```# --- Build Stage ---
# Use a Node.js image to build our TypeScript code
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files and install all dependencies (including devDependencies)
COPY package*.json ./
RUN npm ci

# Copy the rest of the source code
COPY . .

# Run the build script to compile TypeScript to JavaScript
RUN npm run build

# --- Runtime Stage ---
# Use a fresh, lightweight Node.js image for the final product
FROM node:18-alpine AS runtime

WORKDIR /app

# Copy package files and install ONLY production dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Copy the compiled JavaScript code from the build stage
COPY --from=build /app/dist ./dist

EXPOSE 3000

# The command to start the application
CMD [ "node", "dist/index.js" ]
```

Core Docker CommandsBuild the image: docker build -t <your-dockerhub-username>/<image-name> .Run the container: docker run -p 3000:3000 <image-name>List running containers: docker psList all containers (including stopped): docker ps -aView container logs: docker logs <container-name-or-id>2. Multi-Container Development with Docker Compose (Day 2) 🎶Next, we defined the full application stack (API + Database) for local development.The .env FileA .env file was created to securely store secrets. This file must be added to .gitignore and .dockerignore.

```
# Secrets for the PostgreSQL database
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
POSTGRES_DB=mydatabase
```
The Compose FilesTwo separate compose files were created: one for development and one for production.docker-compose.yml (for Development)This file uses the local Dockerfile to build the api service.
```services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_HOST=db
      - POSTGRES_PORT=5432
    restart: unless-stopped
    depends_on:
      - db

  db:
    image: postgres
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```
```
docker-compose.prod.yml (for Production)This file uses the pre-built image from Docker Hub.services:
  api:
    image: <your-dockerhub-username>/<image-name>:latest
    ports:
      - "3000:3000"
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_HOST=db
      - POSTGRES_PORT=5432
    restart: unless-stopped
    depends_on:
      - db

  db:
    image: postgres
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```
Core Docker Compose CommandsStart services (and build if needed): docker-compose up --buildStart services in the background: docker-compose up -dStop and remove services: docker-compose downUse a specific compose file: docker-compose -f docker-compose.prod.yml up -d3. Automated CI/CD with GitHub Actions (Day 3) 🚀Finally, we automated the entire build and deployment process.GitHub SecretsWe configured the following secrets in the repository settings (Settings > Secrets and variables > Actions):DOCKERHUB_USERNAME: Your Docker Hub username.DOCKERHUB_TOKEN: Your Docker Hub access token.AWS_HOST (or EC2_HOST): The public IP of your EC2 instance.AWS_USERNAME: The SSH username for your EC2 instance (e.g., ec2-user).AWS_SSH_KEY (or EC2_SSH_KEY): The private SSH key for deployment.DOCKER_ENV_FILE: The entire contents of your local .env file.The CI Workflow (.github/workflows/ci.yml)This workflow builds the image and pushes it to Docker Hub on every push to main.
```
name: Build Docker Image
on:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: <your-dockerhub-username>/<image-name>:latest
```
The CD Workflow (.github/workflows/cd.yml)This workflow deploys the application to AWS after the CI workflow succeeds.
```
name: Deploy to AWS
on:
  workflow_run:
    workflows: ["Build Docker Image"]
    types:
      - completed

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Copy compose file via scp
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.AWS_HOST }}
          username: ${{ secrets.AWS_USERNAME }}
          key: ${{ secrets.AWS_SSH_KEY }}
          source: "docker-compose.prod.yml"
          target: "."

      - name: Deploy via ssh
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.AWS_HOST }}
          username: ${{ secrets.AWS_USERNAME }}
          key: ${{ secrets.AWS_SSH_KEY }}
          script: |
            echo "${{ secrets.DOCKER_ENV_FILE }}" > .env
            docker pull <your-dockerhub-username>/<image-name>:latest
            docker-compose -f docker-compose.prod.yml up -d
```
