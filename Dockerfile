# Stage 1 - Build stage 
From node:18-alpine AS build

WORKDIR /app

# copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci

# COPY rest of the source code
COPY . .

# Convert TS -> JS
RUN npm run build

# Stage 2 - Runtime stage
FROM node:18-alpine AS runtime

WORKDIR /app

# copy only production dependencies
COPY package*.json ./

# Install dependencies
RUN npm ci --omit=dev

# Copy source code
COPY --from=build /app .

#Expost port
EXPOSE 3000

CMD [ "npm" "start" ]


