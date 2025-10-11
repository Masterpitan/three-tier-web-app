FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.docker.conf /etc/nginx/nginx.conf
EXPOSE 80