# Docker Setup for Three-Tier Web Application

## Quick Start

1. **Build and run all services:**
   ```bash
   docker-compose up --build
   ```

2. **Access the application:**
   - Frontend: http://localhost
   - Backend API: http://localhost:4000
   - Database: localhost:3306

3. **Stop services:**
   ```bash
   docker-compose down
   ```

## Individual Container Commands

**Build containers:**
```bash
docker-compose build
```

**Run in background:**
```bash
docker-compose up -d
```

**View logs:**
```bash
docker-compose logs -f
```

**Clean up (remove volumes):**
```bash
docker-compose down -v
```

## Testing

- Frontend health: http://localhost/health
- Backend health: http://localhost:4000/health
- API endpoint: http://localhost/api/transaction