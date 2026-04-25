from django.urls import path, include

urlpatterns = [
    path("api/restaurants/", include("restaurants.urls")),
    path("api/preferences/", include("preferences.urls")),
]
