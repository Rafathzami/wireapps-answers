FROM node:16-alpine

WORKDIR /app

#if we need to copy the build files we can uncomment below 
#COPY dist/app.js ./ 

#please comment the below line if you're copying from the direct build artifacts 
COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 5000

CMD [ "npm", "start" ]


