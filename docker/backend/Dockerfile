# use official Node.js image as base
FROM node:20-slim

# set working directory inside container
WORKDIR /app

# copy package files and install dependancies
COPY package*.json ./
RUN npm install

#copy the rest of app code
COPY . .

#expose port 5000 to docker host
EXPOSE 5000

#start app
CMD ["npm", "start"]