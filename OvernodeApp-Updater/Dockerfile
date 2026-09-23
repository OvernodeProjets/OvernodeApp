FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production --no-audit
COPY . .
EXPOSE 3344
ENV PORT=3344
ENV NODE_ENV=production
CMD ["node", "server.js"]

