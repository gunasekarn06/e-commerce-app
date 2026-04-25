from rest_framework import serializers
from .models import User, Product, ProductImage, Wishlist, WishlistItem, Category

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'full_name', 'email', 'password', 'is_admin', 'created_at']
        extra_kwargs = {
            'password': {'write_only': True}
        }


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'display_name', 'description', 'is_active', 'created_at', 'updated_at']


class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'image_url', 'order']

class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_display_name = serializers.CharField(source='category.display_name', read_only=True)

    class Meta:
        model = Product
        fields = '__all__'
        # fields = [
        #     'id', 'name', 'description', 'price', 'category', 'category_name', 'category_display_name',
        #     'image_url', 'images', 'stock', 'rating', 'del_flag',
        #     'created_at', 'updated_at', 'created_by'
        # ]
        read_only_fields = ['created_at', 'updated_at', 'created_by']

    def to_representation(self, instance):
        """Custom representation to include is_in_stock"""
        representation = super().to_representation(instance)
        representation['is_in_stock'] = instance.is_in_stock
        return representation


class WishlistItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)

    class Meta:
        model = WishlistItem
        fields = ['id', 'product', 'created_at']


class WishlistSerializer(serializers.ModelSerializer):
    items = WishlistItemSerializer(many=True, read_only=True)

    class Meta:
        model = Wishlist
        fields = ['id', 'user', 'items', 'created_at', 'updated_at']