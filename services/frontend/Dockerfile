# ---------- Build stage ----------
FROM node:20 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --no-audit --omit=dev=false
COPY . .
RUN npm run build || echo "(no build step, using src)"

# ---------- Runtime stage ----------
FROM node:20-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /app/package*.json ./
RUN npm ci --only=production --no-audit && npm cache clean --force
COPY --from=build /app/src ./src
USER node
EXPOSE 3000
CMD ["node", "src/index.js"]