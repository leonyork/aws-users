FROM node:13.10.1-alpine3.11

WORKDIR /app
COPY package-lock.json package.json ./

RUN npm install

COPY rotate-key.js ./

ENTRYPOINT [ "node", "rotate-key.js" ]