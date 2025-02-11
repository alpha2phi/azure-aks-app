# Use official Node.js LTS image (Alpine version)
FROM node:18-alpine

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy application files
COPY server.js .

# Change ownership of the directory
RUN chown -R appuser:appgroup /app

# Set permissions and switch user
USER appuser

# Expose the application port
EXPOSE 3000

# Run the application
CMD ["node", "server.js"]
