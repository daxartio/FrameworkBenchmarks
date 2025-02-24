FROM node:18-slim

COPY ./ ./

RUN npm install

ENV NODE_ENV production

EXPOSE 8080

CMD ["npm", "start"]
