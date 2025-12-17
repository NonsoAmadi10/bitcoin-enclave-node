# --- Build Stage ---
FROM golang:1.18-alpine as builder

WORKDIR /app

# Copy go.mod and go.sum files to download dependencies
COPY go.mod ./
# The go.sum file may not exist yet, but this is a good practice
# COPY go.sum ./ 

# Download dependencies
# RUN go mod download

# Copy the source code for the enclave application
COPY src/enclave/main.go ./src/enclave/

# Build the enclave application
# CGO_ENABLED=0 is important for creating a static binary
# -o /app/enclave-server places the output in the root of the app directory
RUN CGO_ENABLED=0 GOOS=linux go build -v -o /app/enclave-server ./src/enclave

# --- Final Stage ---
# Use a minimal image for the final container
FROM alpine:latest

WORKDIR /root/

# Copy the compiled binary from the builder stage
COPY --from=builder /app/enclave-server .

# The command to run when the container starts
CMD ["./enclave-server"]