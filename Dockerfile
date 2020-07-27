FROM node:12.18.0-alpine as build
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
COPY ./package*.json ./
RUN npm install
RUN npm install react-scripts@3.4.1 -g --silent
COPY . .
RUN npm run build

FROM nginx:1.15.8-alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY --from=build /app/nginx/nginx.conf /etc/nginx

EXPOSE 80
ENTRYPOINT [ "nginx", "-g", "daemon off;" ]
