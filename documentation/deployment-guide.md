# 🚀 Arco Production Deployment Guide

## 📋 Pre-Deployment Checklist

### Environment Configuration
- [ ] Obtain Plant.id API key from [Plant.id](https://plant.id/)
- [ ] Obtain Google Gemini API key from [Google AI Studio](https://makersuite.google.com/)
- [ ] Configure production environment variables
- [ ] Set up domain and SSL certificates
- [ ] Configure monitoring and logging

### Security Checklist
- [ ] API keys stored securely (never in code)
- [ ] Rate limiting configured
- [ ] File upload restrictions enabled
- [ ] CORS properly configured
- [ ] Input validation implemented
- [ ] Error handling doesn't expose sensitive data

---

## 🔧 Backend Deployment

### Option 1: Docker Deployment (Recommended)

1. **Build and Run with Docker:**
```bash
# Build the image
docker build -t arco-backend .

# Run with environment file
docker run -d \
  --name arco-backend \
  -p 3000:3000 \
  --env-file .env \
  -v $(pwd)/logs:/app/logs \
  --restart unless-stopped \
  arco-backend
```

2. **Using Docker Compose:**
```bash
# Production deployment
docker-compose --profile production up -d

# View logs
docker-compose logs -f arco-backend
```

### Option 2: PM2 Deployment

1. **Install PM2:**
```bash
npm install -g pm2
```

2. **Create PM2 Ecosystem File (`ecosystem.config.js`):**
```javascript
module.exports = {
  apps: [{
    name: 'arco-backend',
    script: 'src/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    env_file: '.env',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
```

3. **Start with PM2:**
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### Option 3: Cloud Platform Deployment

#### Heroku
```bash
# Install Heroku CLI and login
heroku login

# Create app
heroku create arco-backend

# Set environment variables
heroku config:set PLANT_ID_API_KEY=your_key_here
heroku config:set GEMINI_API_KEY=your_key_here
heroku config:set NODE_ENV=production

# Deploy
git push heroku main
```

#### Railway
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

#### DigitalOcean App Platform
1. Connect your GitHub repository
2. Set environment variables in the dashboard
3. Configure build and run commands:
   - Build: `npm install`
   - Run: `npm start`

---

## 📱 Flutter App Deployment

### Android Deployment

1. **Configure Signing:**
```bash
# Generate keystore
keytool -genkey -v -keystore ~/arco-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias arco
```

2. **Update `android/app/build.gradle`:**
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

3. **Build Release APK:**
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS Deployment

1. **Configure Xcode Project:**
   - Open `ios/Runner.xcworkspace`
   - Configure signing & capabilities
   - Set deployment target and app icons

2. **Build for Release:**
```bash
flutter build ios --release
```

3. **Archive and Upload:**
   - Use Xcode to archive and upload to App Store Connect

---

## 🔒 Security Configuration

### Environment Variables (.env)
```bash
# Server Configuration
NODE_ENV=production
PORT=3000

# API Keys (NEVER commit these)
PLANT_ID_API_KEY=your_plant_id_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here

# API Configuration
PLANT_ID_API_URL=https://api.plant.id/v3/identification
PLANT_ID_TIMEOUT=30000
GEMINI_MODEL=gemini-pro
GEMINI_MAX_TOKENS=2048

# Security
MAX_FILE_SIZE=10485760
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=info
```

### Nginx Configuration (Optional)
```nginx
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## 📊 Monitoring & Logging

### Health Monitoring
- Set up monitoring for `/health` endpoint
- Configure alerts for API failures
- Monitor response times and error rates

### Log Management
```bash
# View logs with Docker
docker-compose logs -f arco-backend

# View logs with PM2
pm2 logs arco-backend

# Rotate logs
pm2 install pm2-logrotate
```

### Recommended Monitoring Tools
- **Uptime Monitoring:** Pingdom, UptimeRobot
- **Error Tracking:** Sentry
- **Performance:** New Relic, DataDog
- **Logs:** LogDNA, Papertrail

---

## 🔄 CI/CD Pipeline

### GitHub Actions Example (.github/workflows/deploy.yml)
```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run tests
        run: npm test
        
      - name: Deploy to production
        run: |
          # Add your deployment commands here
          echo "Deploying to production..."
```

---

## 🛠️ Maintenance

### Regular Tasks
- [ ] Monitor API usage and costs
- [ ] Update dependencies monthly
- [ ] Review and rotate API keys quarterly
- [ ] Check server resources and scaling needs
- [ ] Backup logs and configurations
- [ ] Update SSL certificates before expiry

### Performance Optimization
- Enable gzip compression
- Implement caching for static responses
- Monitor and optimize database queries (if added)
- Set up CDN for static assets
- Configure load balancing for high traffic

---

## 📞 Support & Troubleshooting

### Common Issues

**API Key Errors:**
- Verify keys are correctly set in environment
- Check API key permissions and quotas
- Ensure keys are not expired

**File Upload Issues:**
- Check file size limits
- Verify allowed file types
- Monitor disk space on server

**High Response Times:**
- Check external API response times
- Monitor server resources
- Review rate limiting settings

### Getting Help
- Check server logs: `docker-compose logs arco-backend`
- Monitor health endpoint: `curl http://localhost:3000/health`
- Review API documentation for correct usage
- Check Plant.id and Gemini API status pages

---

## 📈 Scaling Considerations

### Horizontal Scaling
- Use PM2 cluster mode or Docker Swarm
- Implement load balancing with nginx
- Consider serverless deployment for auto-scaling

### Database Integration
- Add Redis for caching API responses
- Implement PostgreSQL for user data (future)
- Set up database connection pooling

### CDN & Caching
- Implement response caching for repeated requests
- Use CDN for static assets
- Cache conversation starters and language data

---

*Last updated: January 2024*