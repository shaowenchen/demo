FROM node:lts-alpine as builder
WORKDIR /
COPY package.json /
RUN npm install

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /dist/ /usr/share/nginx/html/
EXPOSE 80