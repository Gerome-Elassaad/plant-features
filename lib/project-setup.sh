#!/bin/bash
# setup.sh - aspargo Project Setup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Node.js
    if ! command_exists node; then
        print_error "Node.js is not installed. Please install Node.js 18 or higher."
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version 18 or higher is required. Current: $(node -v)"
        exit 1
    fi
    
    # Check npm
    if ! command_exists npm; then
        print_error "npm is not installed."
        exit 1
    fi
    
    # Check Flutter (optional)
    if command_exists flutter; then
        print_success "Flutter detected: $(flutter --version | head -n 1)"
    else
        print_warning "Flutter not detected. Install Flutter to run the mobile app."
    fi
    
    # Check Docker (optional)
    if command_exists docker; then
        print_success "Docker detected: $(docker --version)"
    else
        print_warning "Docker not detected. Install Docker for containerized deployment."
    fi
    
    print_success "Prerequisites check completed!"
}

# Setup backend
setup_backend() {
    print_status "Setting up backend..."
    
    # Install dependencies
    print_status "Installing Node.js dependencies..."
    npm install
    
    # Create environment file if it doesn't exist
    if [ ! -f .env ]; then
        print_status "Creating .env file from template..."
        cp .env.example .env
        print_warning "Please update the .env file with your API keys and configuration."
    fi
    
    # Create logs directory
    mkdir -p logs
    
    print_success "Backend setup completed!"
}

# Setup Flutter app
setup_flutter() {
    if ! command_exists flutter; then
        print_warning "Flutter not installed. Skipping Flutter setup."
        return
    fi
    
    print_status "Setting up Flutter app..."
    
    # Check if Flutter app directory exists
    if [ -d "lib" ]; then
        print_status "Installing Flutter dependencies..."
        flutter pub get
        
        print_status "Running Flutter doctor..."
        flutter doctor
        
        print_success "Flutter setup completed!"
    else
        print_warning "Flutter app directory not found. Skipping Flutter setup."
    fi
}

# Setup development environment
setup_development() {
    print_status "Setting up development environment..."
    
    # Install development dependencies
    npm install --save-dev
    
    # Setup Git hooks if .git directory exists
    if [ -d ".git" ]; then
        print_status "Setting up Git hooks..."
        # Add any Git hooks setup here
    fi
    
    print_success "Development environment setup completed!"
}

# Run tests
run_tests() {
    print_status "Running backend tests..."
    
    if npm test; then
        print_success "All tests passed!"
    else
        print_error "Some tests failed. Please check the output above."
        exit 1
    fi
}

# Start services
start_services() {
    print_status "Starting services..."
    
    echo "Choose an option:"
    echo "1) Start backend only"
    echo "2) Start with Docker"
    echo "3) Start development mode"
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            print_status "Starting backend..."
            npm start
            ;;
        2)
            if command_exists docker; then
                print_status "Starting with Docker..."
                docker-compose up --build
            else
                print_error "Docker is not installed."
                exit 1
            fi
            ;;
        3)
            print_status "Starting development mode..."
            npm run dev
            ;;
        *)
            print_error "Invalid choice."
            exit 1
            ;;
    esac
}

# Show help
show_help() {
    echo "aspargo Project Setup Script"
    echo ""
    echo "Usage: ./setup.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  --check-prereq    Check prerequisites only"
    echo "  --backend-only    Setup backend only"
    echo "  --flutter-only    Setup Flutter only"
    echo "  --development     Setup development environment"
    echo "  --test           Run tests"
    echo "  --start          Start services"
    echo "  --help           Show this help message"
    echo ""
    echo "Without any options, the script will run complete setup."
}

# Main execution
main() {
    print_status "Starting aspargo project setup..."
    
    case "${1:-}" in
        --check-prereq)
            check_prerequisites
            ;;
        --backend-only)
            check_prerequisites
            setup_backend
            ;;
        --flutter-only)
            setup_flutter
            ;;
        --development)
            check_prerequisites
            setup_backend
            setup_development
            ;;
        --test)
            run_tests
            ;;
        --start)
            start_services
            ;;
        --help)
            show_help
            ;;
        "")
            # Full setup
            check_prerequisites
            setup_backend
            setup_flutter
            setup_development
            print_success "Complete setup finished!"
            echo ""
            print_status "Next steps:"
            echo "1. Update your .env file with API keys"
            echo "2. Run './setup.sh --test' to verify installation"
            echo "3. Run './setup.sh --start' to start the application"
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Make script executable and run main function
main "$@"