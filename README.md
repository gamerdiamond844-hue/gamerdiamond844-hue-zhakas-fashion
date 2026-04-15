# ZHAKAS FASHION

Luxury e-commerce app for the brand **ZHAKAS FASHION**.

## Structure

- `frontend/` - Flutter app for customer and admin mobile UI
- `backend/` - FastAPI backend with JWT auth, PostgreSQL schema, Cloudinary support
- `docs/` - Setup and deployment guide

## Notes

- Backend uses `SECRET_KEY`, `DATABASE_URL`, and Cloudinary credentials from `.env`
- Flutter app API base is configured in `frontend/lib/services/api_service.dart`
- Admin panel is accessible via a hidden secret route in the Flutter app
