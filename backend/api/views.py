from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import User, Product
from .serializers import UserSerializer, ProductSerializer

# GET all users
@api_view(['GET'])
def get_users(request):
    users = User.objects.all()
    serializer = UserSerializer(users, many=True)
    return Response(serializer.data)

# GET single user
@api_view(['GET'])
def get_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        serializer = UserSerializer(user)
        return Response(serializer.data)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

# POST - Create user (Register)
@api_view(['POST'])
def create_user(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# PUT - Update full user
@api_view(['PUT'])
def update_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        serializer = UserSerializer(user, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

# PATCH - Partial update
@api_view(['PATCH'])
def partial_update_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        serializer = UserSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

# DELETE user
@api_view(['DELETE'])
def delete_user(request, pk):
    try:
        user = User.objects.get(pk=pk)
        user.delete()
        return Response({'message': 'User deleted successfully'}, status=status.HTTP_204_NO_CONTENT)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

# LOGIN

@api_view(['POST'])
def login_user(request):
    email = request.data.get('email')
    password = request.data.get('password')

    if not User.objects.filter(email=email).exists():
        return Response(
            {'error': 'Email not registered. Please register first.'},
            status=status.HTTP_404_NOT_FOUND
        )

    try:
        user = User.objects.get(email=email)

        if user.password != password:
            return Response(
                {'error': 'Incorrect password'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        serializer = UserSerializer(user)
        return Response({
            'message': 'Login successful',
            'user': serializer.data
        })

    except User.DoesNotExist:
        return Response(
            {'error': 'Something went wrong'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
# ============= PRODUCT VIEWS =============

@api_view(['GET'])
def get_products(request):
    """Get all active products (del_flag=False)"""
    products = Product.objects.filter(del_flag=False)
    
    # Optional filtering
    category = request.GET.get('category')
    if category:
        products = products.filter(category=category)
    
    serializer = ProductSerializer(products, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def get_all_products_admin(request):
    """Admin: Get ALL products including soft-deleted ones"""
    products = Product.objects.all()
    serializer = ProductSerializer(products, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def get_product_detail(request, pk):
    """Get single product details"""
    try:
        product = Product.objects.get(pk=pk, del_flag=False)
        serializer = ProductSerializer(product)
        return Response(serializer.data)
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
def create_product(request):
    """Admin: Create new product"""
    serializer = ProductSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT'])
def update_product(request, pk):
    """Admin: Update product"""
    try:
        product = Product.objects.get(pk=pk)
        serializer = ProductSerializer(product, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['DELETE'])
def soft_delete_product(request, pk):
    """Admin: Soft delete product (set del_flag=True)"""
    try:
        product = Product.objects.get(pk=pk)
        product.del_flag = True
        product.save()
        return Response(
            {'message': 'Product soft deleted successfully'}, 
            status=status.HTTP_200_OK
        )
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
def restore_product(request, pk):
    """Admin: Restore soft-deleted product"""
    try:
        product = Product.objects.get(pk=pk)
        product.del_flag = False
        product.save()
        return Response(
            {'message': 'Product restored successfully'}, 
            status=status.HTTP_200_OK
        )
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['DELETE'])
def hard_delete_product(request, pk):
    """Admin: Permanently delete product"""
    try:
        product = Product.objects.get(pk=pk)
        product.delete()
        return Response(
            {'message': 'Product permanently deleted'}, 
            status=status.HTTP_204_NO_CONTENT
        )
    except Product.DoesNotExist:
        return Response(
            {'error': 'Product not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )