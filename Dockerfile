# Use the official Node.js image as the base
FROM node:16

# Set the working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the application files
COPY . .

# Expose port 8080
EXPOSE 8080

# Start the application
CMD ["npm", "start"]

