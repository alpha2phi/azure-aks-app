# Use official Node.js LTS image (Alpine version)
FROM node:18-alpine

# Create a system group and user with a fixed UID (1001 for Kubernetes compatibility)
RUN addgroup -S appgroup && adduser -S -G appgroup -u 1001 appuser

# Set working directory
WORKDIR /app

# Copy application files
COPY server.js .

# Change ownership of the directory
RUN chown -R appuser:appgroup /app

# Use the non-root user for security
USER 1001

# Expose the application port
EXPOSE 3000

# Run the application
CMD ["node", "server.js"]
