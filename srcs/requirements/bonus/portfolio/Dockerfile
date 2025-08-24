FROM node:18-alpine

# Install serve package globally
RUN npm install -g serve

# Create app directory
WORKDIR /app

# Copy website files
COPY ./site /app

# Expose port
EXPOSE 3000

# Start the static server
CMD ["serve", "-s", ".", "-l", "3000"]
