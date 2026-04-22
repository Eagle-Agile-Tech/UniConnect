FROM node:20-alpine

WORKDIR /app
RUN apk add --no-cache postgresql-client
# Install dependencies for both backend packages.
COPY src/package*.json ./src/
COPY Database/package*.json ./Database/
RUN cd /app/src && npm ci --legacy-peer-deps
RUN cd /app/Database && npm ci

# Copy source after installing dependencies to maximize layer cache.
COPY src ./src
COPY Database ./Database

# Prisma client is generated at container runtime (see docker-compose command).

EXPOSE 3000

WORKDIR /app/src
CMD ["sh", "-c", "npm run db:migrate && npm run start"]
