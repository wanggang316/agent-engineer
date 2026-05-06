# syntax=docker/dockerfile:1.7

# ---------- Stage 1: build ----------
FROM node:22-alpine AS build
WORKDIR /app

# Install deps with cache-friendly layer
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Copy source and build static site
COPY . .
RUN npm run build

# ---------- Stage 2: serve ----------
FROM nginx:1.27-alpine AS runtime

# Drop default config, use ours
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static site
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

# nginx:alpine ships with HEALTHCHECK-friendly /
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD wget -qO- http://localhost/ >/dev/null 2>&1 || exit 1

CMD ["nginx", "-g", "daemon off;"]
