FROM node:20-alpine

WORKDIR /app

# Install dependencies for both backend packages.
COPY src/package*.json ./src/
COPY Database/package*.json ./Database/
RUN cd /app/src && npm ci --legacy-peer-deps
RUN cd /app/Database && npm ci

# Copy source after installing dependencies to maximize layer cache.
COPY src ./src
COPY Database ./Database

# Generate Prisma client used by /app/src/lib/prisma.js.
RUN cd /app/Database && npx prisma generate --schema prisma/schema.prisma

EXPOSE 3000

WORKDIR /app/src
CMD ["npm", "run", "start"]
