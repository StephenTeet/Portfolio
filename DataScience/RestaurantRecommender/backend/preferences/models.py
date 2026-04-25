from django.db import models

class UserSession(models.Model):
    session_key = models.CharField(max_length=64, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    user_lat = models.FloatField()
    user_lon = models.FloatField()

class CuisineRanking(models.Model):
    session = models.ForeignKey(UserSession, on_delete=models.CASCADE)
    cuisine = models.CharField(max_length=64)
    rank = models.PositiveIntegerField()

class PastRestaurant(models.Model):
    session = models.ForeignKey(UserSession, on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    cuisine = models.CharField(max_length=64)
    rating = models.IntegerField()  # 1-5

class UserPreference(models.Model):
    session = models.OneToOneField(UserSession, on_delete=models.CASCADE)
    price_min = models.IntegerField(default=1)
    price_max = models.IntegerField(default=3)
    max_drive_minutes = models.IntegerField(default=20)
