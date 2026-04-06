from rest_framework import serializers
from .models import User, Product

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'full_name', 'email', 'password', 'is_admin', 'created_at']
        extra_kwargs = {'password': {'write_only': True}}


class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 'category', 
            'image_url', 'stock', 'rating', 'del_flag', 
            'created_at', 'updated_at', 'created_by'
        ]
        read_only_fields = ['created_at', 'updated_at']

    def to_representation(self, instance):
        """Custom representation to include is_in_stock"""
        representation = super().to_representation(instance)
        representation['is_in_stock'] = instance.is_in_stock
        return representation