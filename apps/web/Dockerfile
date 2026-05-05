FROM node:20-alpine

WORKDIR /app

# Install frontend dependencies from the nested web app folder.
COPY frontend/package*.json ./frontend/
WORKDIR /app/frontend
RUN npm ci --omit=dev

# Copy frontend source and run the app.
COPY frontend/ ./
EXPOSE 3000
CMD ["npm", "start"]