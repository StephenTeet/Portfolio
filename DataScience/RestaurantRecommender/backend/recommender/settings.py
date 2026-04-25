# only key parts so far
INSTALLED_APPS = [
    ...
    'rest_framework',
    'corsheaders',
    'restaurants',
    'preferences',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    ...
]

CORS_ALLOWED_ORIGINS = ["http://localhost:5173"]  # Vite dev server

REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
}
