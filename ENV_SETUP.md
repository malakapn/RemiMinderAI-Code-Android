# MediMinder Environment Setup Guide

## 📁 Where to Create .env Files

### Option 1: Centralized (Recommended for Monorepo)
Create **one .env file** at the project root:
```
/Users/jibinkunjumon/developments/MediMinder/.env
```

### Option 2: App-Specific (Alternative)
Create separate .env files in each app:
- `apps/backend/.env` - for Python backend
- `apps/mobile/.env` - for Flutter mobile app

## 🔑 Required Environment Variables

### For Both Backend & Mobile App:
```bash
# =============================================================================
# SUPABASE CONFIGURATION (Get from Supabase Dashboard)
# =============================================================================
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# =============================================================================
# GOOGLE OAUTH CONFIGURATION (For Mobile App)
# =============================================================================
# Google Sign-In Client ID (from Google Cloud Console)
# For iOS: com.googleusercontent.apps.xxxxxxxxxx-xxxxxxxxxxxxxxxxxx
# For Android: xxxxxxxxxx-xxxxxxxxxxxxxxxxxx.googleusercontent.com
GOOGLE_CLIENT_ID=your-google-client-id-here

# =============================================================================
# API CONFIGURATION
# =============================================================================
API_BASE_URL=http://localhost:8000
FLUTTER_ENV=development
```

### Backend Only:
```bash
# =============================================================================
# BACKEND SERVER CONFIGURATION
# =============================================================================
HOST=0.0.0.0
PORT=8000
DEBUG=True
```

## 🚀 How to Get Supabase Keys

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to Settings → API
4. Copy the values:
   - **Project URL** → `SUPABASE_URL`
   - **anon/public key** → `SUPABASE_ANON_KEY`
   - **service_role key** → `SUPABASE_SERVICE_ROLE_KEY`

## 📝 Create Your .env File

**At project root**, create `.env`:

```bash
# MediMinder Environment Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
API_BASE_URL=http://localhost:8000
FLUTTER_ENV=development
HOST=0.0.0.0
PORT=8000
DEBUG=True
```

## ✅ Next Steps

1. Create the .env file with your actual Supabase keys
2. Test backend: `cd apps/backend && python main.py`
3. Test mobile app authentication integration

## 🔒 Security Notes

- Never commit .env files to git
- Service role key has admin privileges - keep it secret
- Use different keys for development/staging/production
