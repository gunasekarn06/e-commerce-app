// import 'package:flutter/material.dart';
// import '../services/api_service.dart';
// import '../services/razorpay_service.dart';

// const Color kBrandRed = Color(0xFFE4252A);
// const Color kTextDark = Color(0xFF1A1A1A);
// const Color kTextMuted = Color(0xFF6B6B6B);
// const Color kSurface = Color(0xFFF7F7F7);
// const Color kBorder = Color(0xFFEAEAEA);

// class CheckoutPage extends StatefulWidget {
//   final int userId;
//   final List<Map<String, dynamic>> selectedItems;
//   final bool promoApplied;
//   final double deliveryFee;
//   final double discountPercent;

//   const CheckoutPage({
//     super.key,
//     required this.userId,
//     required this.selectedItems,
//     required this.promoApplied,
//     required this.deliveryFee,
//     required this.discountPercent,
//   });

//   @override
//   State<CheckoutPage> createState() => _CheckoutPageState();
// }

// class _CheckoutPageState extends State<CheckoutPage> {
//   // 🔑 Only Key ID here — Key Secret goes on your backend ONLY
//   static const String _razorpayKeyId = 'rzp_test_Sjf5R4l0R8Ah9G';

//   final RazorpayService _razorpayService = RazorpayService();

//   List<Map<String, dynamic>> _savedAddresses = [];
//   bool _isLoadingAddresses = true;
//   int? _selectedAddressId;
//   bool _showAddressForm = false;

//   final _formKey = GlobalKey<FormState>();
//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _addressLine1Controller = TextEditingController();
//   final _addressLine2Controller = TextEditingController();
//   final _cityController = TextEditingController();
//   final _postalCodeController = TextEditingController();

//   static const List<String> _countries = ['India', 'United States', 'Canada'];
//   static const Map<String, List<String>> _statesByCountry = {
//     'India': [
//       'Tamil Nadu',
//       'Karnataka',
//       'Kerala',
//       'Maharashtra',
//       'Delhi',
//       'Telangana',
//     ],
//     'United States': [
//       'California',
//       'Texas',
//       'New York',
//       'Florida',
//       'Washington',
//     ],
//     'Canada': ['Ontario', 'British Columbia', 'Quebec', 'Alberta'],
//   };
//   static const List<String> _addressTypes = ['home', 'office', 'other'];

//   String _selectedCountry = 'India';
//   String? _selectedState = 'Tamil Nadu';
//   String _selectedAddressType = 'home';
//   String _paymentMethod = 'upi';
//   bool _isPlacingOrder = false;
//   bool _isSavingAddress = false;

//   @override
//   void initState() {
//     super.initState();

//     _razorpayService.init(
//       onSuccess: _handlePaymentSuccess,
//       onError: _handlePaymentError,
//     );

//     _loadSavedAddresses();
//   }

//   @override
//   void dispose() {
//     _razorpayService.clear();

//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _addressLine1Controller.dispose();
//     _addressLine2Controller.dispose();
//     _cityController.dispose();
//     _postalCodeController.dispose();
//     super.dispose();
//   }

//   // ─── Razorpay Event Handlers ──────────────────────────────────────────────────

//   // ✅ Called when payment succeeds
//   void _handlePaymentSuccess(String paymentId) {
//     debugPrint('✅ Razorpay Payment Success: $paymentId');
//     if (!mounted) return;
//     _submitOrderToBackend(paymentId: paymentId);
//   }

//   // ✅ Called when payment fails or user cancels
//   void _handlePaymentError(String message, bool isCancelled) {
//     debugPrint('❌ Razorpay Payment Error: $message');
//     if (!mounted) return;
//     setState(() => _isPlacingOrder = false);
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => _CheckoutOutcomePage(
//           success: false,
//           title: isCancelled ? 'Payment Cancelled' : 'Payment Failed',
//           message: isCancelled
//               ? 'No amount was charged. You can review the order and try again whenever you are ready.'
//               : message,
//           amount: total,
//           itemsCount: _itemsCount,
//           paymentMethodLabel: _paymentMethodLabel,
//           address: _selectedAddress,
//           selectedItems: widget.selectedItems,
//           primaryLabel: 'Try Again',
//           secondaryLabel: 'Back to Checkout',
//           popWithSuccess: false,
//         ),
//       ),
//     );
//   }

//   // ─── Open Razorpay Checkout ───────────────────────────────────────────────────

//   void _openRazorpayCheckout() {
//     final int amountInPaise = (total * 100).round();

//     final options = <String, dynamic>{
//       'key': _razorpayKeyId,
//       'amount': amountInPaise, // In paise (₹1 = 100 paise)
//       'currency': 'INR',
//       'name': 'Your App Name', // 🔧 Change to your brand name
//       'description': 'Order Payment',
//       'theme': {'color': '#E4252A'},
//       'prefill': {
//         'contact': '9999999999', // 🔧 Pass real user phone if available
//         'email': 'user@example.com', // 🔧 Pass real user email if available
//       },
//       'external': {
//         'wallets': ['paytm', 'phonepe'],
//       },
//     };

//     try {
//       _razorpayService.open(options);
//     } catch (e) {
//       debugPrint('Razorpay open error: $e');
//       setState(() => _isPlacingOrder = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not open payment gateway: $e')),
//         );
//       }
//     }
//   }

//   // ─── Submit Order to Backend ─────────────────────────────────────────────────

//   Future<void> _submitOrderToBackend({String? paymentId}) async {
//     setState(() => _isPlacingOrder = true);

//     final result = await ApiService.checkoutCart(
//       userId: widget.userId,
//       productIds: widget.selectedItems
//           .map<int>((item) => item['product_id'] as int)
//           .toList(),
//       addressId: _selectedAddressId,
//       paymentMethod: _paymentMethod,
//       // Pass paymentId to backend for verification if needed:
//       // paymentId: paymentId,
//     );

//     if (!mounted) return;
//     setState(() => _isPlacingOrder = false);

//     if (result['success'] == true) {
//       final payload = result['data'];
//       Map<String, dynamic>? order;
//       if (payload is Map && payload['order'] is Map) {
//         order = Map<String, dynamic>.from(payload['order'] as Map);
//       }

//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (_) => _CheckoutOutcomePage(
//             success: true,
//             title: _paymentMethod == 'cod'
//                 ? 'Order Confirmed'
//                 : 'Payment Successful',
//             message: _paymentMethod == 'cod'
//                 ? 'Your order has been placed successfully and payment will be collected at delivery.'
//                 : 'Your payment was received and your order is now confirmed.',
//             amount: _readAmount(order?['total_amount']),
//             itemsCount: _readCount(order?['total_items']),
//             paymentMethodLabel: _paymentMethodLabel,
//             paymentId: paymentId,
//             orderId: order?['id']?.toString(),
//             address: order ?? _selectedAddress,
//             selectedItems: widget.selectedItems,
//             primaryLabel: 'Continue Shopping',
//             secondaryLabel: 'Done',
//             popWithSuccess: true,
//           ),
//         ),
//       );
//     } else {
//       final bool paymentWasCaptured = paymentId != null && paymentId.isNotEmpty;
//       final String errorMessage =
//           result['error']?.toString() ?? 'Failed to place order';

//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (_) => _CheckoutOutcomePage(
//             success: false,
//             title: paymentWasCaptured ? 'Payment Received' : 'Order Failed',
//             message: paymentWasCaptured
//                 ? 'Your payment went through, but we could not confirm the order right now. Please keep this payment ID for support.'
//                 : errorMessage,
//             amount: total,
//             itemsCount: _itemsCount,
//             paymentMethodLabel: _paymentMethodLabel,
//             paymentId: paymentId,
//             address: _selectedAddress,
//             selectedItems: widget.selectedItems,
//             primaryLabel: paymentWasCaptured ? 'Back to Cart' : 'Try Again',
//             secondaryLabel: paymentWasCaptured ? 'Close' : 'Back to Checkout',
//             popWithSuccess: false,
//           ),
//         ),
//       );
//     }
//   }

//   // ─── Place Order Entry Point ──────────────────────────────────────────────────

//   Future<void> _placeOrder() async {
//     if (_selectedAddressId == null && !_showAddressForm) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a delivery address')),
//       );
//       return;
//     }

//     if (_showAddressForm) {
//       await _saveNewAddress();
//       if (_selectedAddressId == null) return;
//     }

//     setState(() => _isPlacingOrder = true);

//     if (_paymentMethod == 'cod') {
//       // Cash on Delivery → skip Razorpay, go straight to backend
//       await _submitOrderToBackend();
//     } else {
//       // UPI/Card → open Razorpay native checkout
//       // _isPlacingOrder stays true until handler fires
//       _openRazorpayCheckout();
//     }
//   }

//   // ─── Address ─────────────────────────────────────────────────────────────────

//   Future<void> _loadSavedAddresses() async {
//     setState(() => _isLoadingAddresses = true);
//     final result = await ApiService.getUserAddresses(widget.userId);
//     if (!mounted) return;
//     setState(() {
//       _isLoadingAddresses = false;
//       if (result['addresses'] != null) {
//         _savedAddresses = List<Map<String, dynamic>>.from(result['addresses']);
//         if (_savedAddresses.isNotEmpty) {
//           final defaultAddress = _savedAddresses.firstWhere(
//             (addr) => addr['is_default'] == true,
//             orElse: () => _savedAddresses.first,
//           );
//           _selectedAddressId = defaultAddress['id'];
//         } else {
//           _showAddressForm = true;
//         }
//       }
//     });
//   }

//   List<String> get _stateOptions =>
//       _statesByCountry[_selectedCountry] ?? const <String>[];

//   double get subtotal => widget.selectedItems.fold(
//     0.0,
//     (sum, item) => sum + ((item['price'] as num) * (item['quantity'] as num)),
//   );

//   double get total =>
//       subtotal + widget.deliveryFee - (subtotal * widget.discountPercent / 100);

//   Future<void> _saveNewAddress() async {
//     if (!_formKey.currentState!.validate() || _selectedState == null) {
//       if (_selectedState == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select a state / province')),
//         );
//       }
//       return;
//     }
//     setState(() => _isSavingAddress = true);
//     final result = await ApiService.createAddress(
//       userId: widget.userId,
//       addressData: {
//         'address_type': _selectedAddressType,
//         'first_name': _firstNameController.text.trim(),
//         'last_name': _lastNameController.text.trim(),
//         'address_line_1': _addressLine1Controller.text.trim(),
//         'address_line_2': _addressLine2Controller.text.trim(),
//         'city': _cityController.text.trim(),
//         'state': _selectedState,
//         'postal_code': _postalCodeController.text.trim(),
//         'country': _selectedCountry,
//         'is_default': _savedAddresses.isEmpty,
//       },
//     );
//     if (!mounted) return;
//     setState(() => _isSavingAddress = false);
//     if (result['success'] == true) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Address saved successfully'),
//           backgroundColor: Color(0xFF1DB954),
//         ),
//       );
//       _clearForm();
//       await _loadSavedAddresses();
//       setState(() => _showAddressForm = false);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             result['error']?.toString() ?? 'Failed to save address',
//           ),
//         ),
//       );
//     }
//   }

//   void _clearForm() {
//     _firstNameController.clear();
//     _lastNameController.clear();
//     _addressLine1Controller.clear();
//     _addressLine2Controller.clear();
//     _cityController.clear();
//     _postalCodeController.clear();
//     setState(() {
//       _selectedCountry = 'India';
//       _selectedState = 'Tamil Nadu';
//       _selectedAddressType = 'home';
//     });
//   }

//   Map<String, dynamic>? get _selectedAddress {
//     if (_selectedAddressId == null) return null;

//     for (final address in _savedAddresses) {
//       if (address['id'] == _selectedAddressId) {
//         return Map<String, dynamic>.from(address);
//       }
//     }
//     return null;
//   }

//   int get _itemsCount => widget.selectedItems.fold<int>(
//     0,
//     (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
//   );

//   String get _paymentMethodLabel =>
//       _paymentMethod == 'cod' ? 'Cash on Delivery' : 'UPI / Card';

//   double _readAmount(dynamic value) =>
//       double.tryParse(value?.toString() ?? '') ?? total;

//   int _readCount(dynamic value) =>
//       int.tryParse(value?.toString() ?? '') ?? _itemsCount;

//   Future<void> _confirmDeleteAddress(int addressId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Address'),
//         content: const Text('Are you sure you want to delete this address?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//     if (confirm == true) {
//       final result = await ApiService.deleteAddress(
//         addressId: addressId,
//         userId: widget.userId,
//       );
//       if (!mounted) return;
//       if (result['success'] == true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Address deleted'),
//             backgroundColor: Color(0xFF1DB954),
//           ),
//         );
//         await _loadSavedAddresses();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               result['error']?.toString() ?? 'Failed to delete address',
//             ),
//           ),
//         );
//       }
//     }
//   }

//   // ─── Build ───────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//         title: const Text(
//           'Checkout',
//           style: TextStyle(
//             color: kBrandRed,
//             fontSize: 21,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   _buildAddressSection(),
//                   const SizedBox(height: 16),
//                   _buildSection(
//                     title: 'Order Summary',
//                     child: Column(
//                       children: [
//                         for (final item in widget.selectedItems) ...[
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 60,
//                                 height: 60,
//                                 decoration: BoxDecoration(
//                                   color: kSurface,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(12),
//                                   child: Image.network(
//                                     item['image'],
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (_, __, ___) => const Icon(
//                                       Icons.image_outlined,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       item['product_name'],
//                                       style: const TextStyle(
//                                         fontSize: 15,
//                                         fontWeight: FontWeight.w700,
//                                         color: kTextDark,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       'Qty: ${item['quantity']}',
//                                       style: const TextStyle(
//                                         color: kTextMuted,
//                                         fontSize: 13,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Text(
//                                 '₹${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)}',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w700,
//                                   color: kTextDark,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                         ],
//                         const Divider(color: kBorder),
//                         _summaryRow(
//                           'Subtotal',
//                           '₹${subtotal.toStringAsFixed(2)}',
//                         ),
//                         _summaryRow(
//                           'Delivery Fee',
//                           '₹${widget.deliveryFee.toStringAsFixed(2)}',
//                         ),
//                         if (widget.promoApplied)
//                           _summaryRow(
//                             'Discount',
//                             '${widget.discountPercent.toInt()}%',
//                           ),
//                         const SizedBox(height: 6),
//                         _summaryRow(
//                           'Total',
//                           '₹${total.toStringAsFixed(2)}',
//                           emphasize: true,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildSection(
//                     title: 'Payment Details',
//                     child: Column(
//                       children: [
//                         RadioListTile<String>(
//                           value: 'upi',
//                           groupValue: _paymentMethod,
//                           activeColor: kBrandRed,
//                           contentPadding: EdgeInsets.zero,
//                           title: const Text('UPI / Card'),
//                           subtitle: const Text('Pay securely via Razorpay'),
//                           secondary: const Icon(
//                             Icons.payment,
//                             color: kBrandRed,
//                           ),
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() => _paymentMethod = value);
//                             }
//                           },
//                         ),
//                         const Divider(color: kBorder),
//                         RadioListTile<String>(
//                           value: 'cod',
//                           groupValue: _paymentMethod,
//                           activeColor: kBrandRed,
//                           contentPadding: EdgeInsets.zero,
//                           title: const Text('Cash on Delivery'),
//                           subtitle: const Text('Pay when the order arrives'),
//                           secondary: const Icon(
//                             Icons.money,
//                             color: Colors.green,
//                           ),
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() => _paymentMethod = value);
//                             }
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   onPressed: _isPlacingOrder ? null : _placeOrder,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kBrandRed,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   child: _isPlacingOrder
//                       ? const SizedBox(
//                           width: 22,
//                           height: 22,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2.4,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               _paymentMethod == 'cod'
//                                   ? Icons.money
//                                   : Icons.lock_outline,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               _paymentMethod == 'cod'
//                                   ? 'Place Order ₹${total.toStringAsFixed(2)}'
//                                   : 'Pay ₹${total.toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAddressSection() {
//     return _buildSection(
//       title: 'Delivery Address',
//       child: _isLoadingAddresses
//           ? const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(20),
//                 child: CircularProgressIndicator(color: kBrandRed),
//               ),
//             )
//           : Column(
//               children: [
//                 if (_savedAddresses.isNotEmpty && !_showAddressForm)
//                   ..._savedAddresses.map(
//                     (address) => _buildAddressCard(address),
//                   ),
//                 if (!_showAddressForm)
//                   InkWell(
//                     onTap: () => setState(() {
//                       _showAddressForm = true;
//                       _selectedAddressId = null;
//                     }),
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: kBorder, width: 1.5),
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                       child: const Row(
//                         children: [
//                           Icon(
//                             Icons.add_circle_outline,
//                             color: kBrandRed,
//                             size: 24,
//                           ),
//                           SizedBox(width: 12),
//                           Text(
//                             'Add New Address',
//                             style: TextStyle(
//                               color: kBrandRed,
//                               fontSize: 15,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 if (_showAddressForm) _buildAddressForm(),
//               ],
//             ),
//     );
//   }

//   Widget _buildAddressCard(Map<String, dynamic> address) {
//     final isSelected = _selectedAddressId == address['id'];
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: isSelected ? kBrandRed : kBorder,
//           width: isSelected ? 2 : 1,
//         ),
//         borderRadius: BorderRadius.circular(14),
//         color: isSelected ? kBrandRed.withOpacity(0.05) : Colors.white,
//       ),
//       child: InkWell(
//         onTap: () => setState(() {
//           _selectedAddressId = address['id'];
//           _showAddressForm = false;
//         }),
//         borderRadius: BorderRadius.circular(14),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Radio<int>(
//                 value: address['id'],
//                 groupValue: _selectedAddressId,
//                 activeColor: kBrandRed,
//                 onChanged: (value) => setState(() {
//                   _selectedAddressId = value;
//                   _showAddressForm = false;
//                 }),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         _tag(
//                           address['address_type'].toString().toUpperCase(),
//                           kBrandRed,
//                         ),
//                         if (address['is_default'] == true) ...[
//                           const SizedBox(width: 8),
//                           _tag('DEFAULT', Colors.green),
//                         ],
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${address['first_name']} ${address['last_name']}',
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                         color: kTextDark,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       address['address_line_1'],
//                       style: const TextStyle(fontSize: 13, color: kTextMuted),
//                     ),
//                     if (address['address_line_2']?.isNotEmpty == true)
//                       Text(
//                         address['address_line_2'],
//                         style: const TextStyle(fontSize: 13, color: kTextMuted),
//                       ),
//                     Text(
//                       '${address['city']}, ${address['state']} ${address['postal_code']}',
//                       style: const TextStyle(fontSize: 13, color: kTextMuted),
//                     ),
//                     Text(
//                       address['country'],
//                       style: const TextStyle(fontSize: 13, color: kTextMuted),
//                     ),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete_outline, color: Colors.red),
//                 onPressed: () => _confirmDeleteAddress(address['id']),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _tag(String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: color,
//           fontSize: 11,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildAddressForm() {
//     return Form(
//       key: _formKey,
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'New Address',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   color: kTextDark,
//                 ),
//               ),
//               if (_savedAddresses.isNotEmpty)
//                 TextButton(
//                   onPressed: () => setState(() {
//                     _showAddressForm = false;
//                     _clearForm();
//                     if (_savedAddresses.isNotEmpty) {
//                       _selectedAddressId = _savedAddresses.first['id'];
//                     }
//                   }),
//                   child: const Text('Cancel'),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _buildDropdownField<String>(
//             value: _selectedAddressType,
//             label: 'Address Type',
//             items: _addressTypes,
//             onChanged: (value) {
//               if (value != null) setState(() => _selectedAddressType = value);
//             },
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildTextField(
//                   controller: _firstNameController,
//                   label: 'First Name',
//                   hint: 'Required',
//                   validator: _requiredValidator,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildTextField(
//                   controller: _lastNameController,
//                   label: 'Last Name',
//                   hint: 'Required',
//                   validator: _requiredValidator,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _buildTextField(
//             controller: _addressLine1Controller,
//             label: 'Address Line 1',
//             hint: 'Street address, P.O. box',
//             validator: _requiredValidator,
//           ),
//           const SizedBox(height: 12),
//           _buildTextField(
//             controller: _addressLine2Controller,
//             label: 'Address Line 2',
//             hint: 'Apartment, suite, unit',
//           ),
//           const SizedBox(height: 12),
//           _buildTextField(
//             controller: _cityController,
//             label: 'City',
//             hint: 'Required',
//             validator: _requiredValidator,
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildDropdownField<String>(
//                   value: _selectedState,
//                   label: 'State / Province',
//                   items: _stateOptions,
//                   onChanged: (value) => setState(() => _selectedState = value),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildTextField(
//                   controller: _postalCodeController,
//                   label: 'Postal Code',
//                   hint: 'Required',
//                   validator: _requiredValidator,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _buildDropdownField<String>(
//             value: _selectedCountry,
//             label: 'Country',
//             items: _countries,
//             onChanged: (value) {
//               if (value != null) {
//                 setState(() {
//                   _selectedCountry = value;
//                   final nextStates =
//                       _statesByCountry[_selectedCountry] ?? const [];
//                   _selectedState = nextStates.isNotEmpty
//                       ? nextStates.first
//                       : null;
//                 });
//               }
//             },
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             height: 48,
//             child: ElevatedButton(
//               onPressed: _isSavingAddress ? null : _saveNewAddress,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: kBrandRed,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: _isSavingAddress
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     )
//                   : const Text(
//                       'Save Address',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 15,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSection({required String title, required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               color: kTextDark,
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 16),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             color: kTextDark,
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           validator: validator,
//           decoration: InputDecoration(
//             hintText: hint,
//             filled: true,
//             fillColor: kSurface,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 14,
//               vertical: 14,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: const BorderSide(color: kBorder),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: const BorderSide(color: kBrandRed, width: 1.3),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdownField<T>({
//     required T? value,
//     required String label,
//     required List<T> items,
//     required ValueChanged<T?> onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             color: kTextDark,
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<T>(
//           value: value,
//           items: items
//               .map(
//                 (item) => DropdownMenuItem<T>(
//                   value: item,
//                   child: Text(item.toString()),
//                 ),
//               )
//               .toList(),
//           onChanged: onChanged,
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: kSurface,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 14,
//               vertical: 14,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: const BorderSide(color: kBorder),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: const BorderSide(color: kBrandRed, width: 1.3),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _summaryRow(String label, String value, {bool emphasize = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: emphasize ? kTextDark : kTextMuted,
//               fontSize: emphasize ? 15 : 14,
//               fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               color: kTextDark,
//               fontSize: emphasize ? 16 : 14,
//               fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String? _requiredValidator(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'This field is required';
//     }
//     return null;
//   }
// }

// class _CheckoutOutcomePage extends StatelessWidget {
//   final bool success;
//   final String title;
//   final String message;
//   final double amount;
//   final int itemsCount;
//   final String paymentMethodLabel;
//   final String? paymentId;
//   final String? orderId;
//   final Map<String, dynamic>? address;
//   final List<Map<String, dynamic>> selectedItems;
//   final String primaryLabel;
//   final String? secondaryLabel;
//   final bool popWithSuccess;

//   const _CheckoutOutcomePage({
//     required this.success,
//     required this.title,
//     required this.message,
//     required this.amount,
//     required this.itemsCount,
//     required this.paymentMethodLabel,
//     required this.address,
//     required this.selectedItems,
//     required this.primaryLabel,
//     required this.popWithSuccess,
//     this.paymentId,
//     this.orderId,
//     this.secondaryLabel,
//   });

//   Color get _accent =>
//       success ? const Color(0xFF16A34A) : const Color(0xFFE4252A);

//   Color get _softAccent =>
//       success ? const Color(0xFFEAF8EF) : const Color(0xFFFDECEC);

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         Navigator.pop(context, popWithSuccess);
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF4F5F7),
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           automaticallyImplyLeading: !success,
//         ),
//         body: SafeArea(
//           child: Column(
//             children: [
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
//                   children: [
//                     _buildHero(),
//                     const SizedBox(height: 18),
//                     _buildSummaryCard(),
//                     if (_resolvedAddressText.isNotEmpty) ...[
//                       const SizedBox(height: 14),
//                       _buildAddressCard(),
//                     ],
//                     if (selectedItems.isNotEmpty) ...[
//                       const SizedBox(height: 14),
//                       _buildItemsCard(),
//                     ],
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//                 ),
//                 child: Column(
//                   children: [
//                     SizedBox(
//                       width: double.infinity,
//                       height: 54,
//                       child: ElevatedButton(
//                         onPressed: () => Navigator.pop(context, popWithSuccess),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _accent,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                         ),
//                         child: Text(
//                           primaryLabel,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                       ),
//                     ),
//                     if (secondaryLabel != null) ...[
//                       const SizedBox(height: 10),
//                       SizedBox(
//                         width: double.infinity,
//                         height: 52,
//                         child: OutlinedButton(
//                           onPressed: () =>
//                               Navigator.pop(context, success ? true : null),
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: kTextDark,
//                             side: const BorderSide(color: kBorder),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           child: Text(
//                             secondaryLabel!,
//                             style: const TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHero() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: success
//               ? const [Color(0xFF0F9D58), Color(0xFF1DB954)]
//               : const [Color(0xFFD93025), Color(0xFFE4252A)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//             color: _accent.withOpacity(0.24),
//             blurRadius: 24,
//             offset: const Offset(0, 14),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Container(
//             width: 88,
//             height: 88,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.18),
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.white.withOpacity(0.35)),
//             ),
//             child: Icon(
//               success ? Icons.check_rounded : Icons.close_rounded,
//               color: Colors.white,
//               size: 52,
//             ),
//           ),
//           const SizedBox(height: 18),
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 26,
//               fontWeight: FontWeight.w900,
//               letterSpacing: -0.4,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             message,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.92),
//               fontSize: 14,
//               height: 1.45,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryCard() {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(22),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Payment Summary',
//             style: TextStyle(
//               color: kTextDark,
//               fontSize: 18,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 14),
//           _summaryRow(
//             icon: Icons.currency_rupee_rounded,
//             label: 'Amount',
//             value: '₹${amount.toStringAsFixed(2)}',
//             accent: _accent,
//           ),
//           const SizedBox(height: 10),
//           _summaryRow(
//             icon: Icons.shopping_bag_outlined,
//             label: 'Items',
//             value: '$itemsCount item${itemsCount == 1 ? '' : 's'}',
//             accent: const Color(0xFF1565C0),
//           ),
//           const SizedBox(height: 10),
//           _summaryRow(
//             icon: Icons.account_balance_wallet_outlined,
//             label: 'Payment Mode',
//             value: paymentMethodLabel,
//             accent: const Color(0xFFF57C00),
//           ),
//           if (orderId != null) ...[
//             const SizedBox(height: 10),
//             _summaryRow(
//               icon: Icons.receipt_long_outlined,
//               label: 'Order ID',
//               value: '#$orderId',
//               accent: const Color(0xFF6A1B9A),
//             ),
//           ],
//           if (paymentId != null && paymentId!.isNotEmpty) ...[
//             const SizedBox(height: 10),
//             _summaryRow(
//               icon: Icons.verified_outlined,
//               label: 'Payment ID',
//               value: paymentId!,
//               accent: success
//                   ? const Color(0xFF1DB954)
//                   : const Color(0xFFE4252A),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildAddressCard() {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(22),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: _softAccent,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(Icons.location_on_outlined, color: _accent),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Delivering To',
//                   style: TextStyle(
//                     color: kTextDark,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   _resolvedAddressText,
//                   style: const TextStyle(
//                     color: kTextMuted,
//                     fontSize: 13.5,
//                     height: 1.45,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildItemsCard() {
//     final previewItems = selectedItems.take(3).toList();

//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(22),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Order Items',
//             style: TextStyle(
//               color: kTextDark,
//               fontSize: 18,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 14),
//           for (final item in previewItems) ...[
//             Row(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(14),
//                   child: Container(
//                     width: 56,
//                     height: 56,
//                     color: const Color(0xFFF4F5F7),
//                     child: item['image'] != null
//                         ? Image.network(
//                             item['image'],
//                             fit: BoxFit.cover,
//                             errorBuilder: (_, __, ___) => const Icon(
//                               Icons.image_outlined,
//                               color: kTextMuted,
//                             ),
//                           )
//                         : const Icon(Icons.image_outlined, color: kTextMuted),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item['product_name']?.toString() ?? 'Product',
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           color: kTextDark,
//                           fontSize: 14.5,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Qty ${item['quantity']}',
//                         style: const TextStyle(
//                           color: kTextMuted,
//                           fontSize: 12.5,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   '₹${(((item['price'] as num?) ?? 0) * ((item['quantity'] as num?) ?? 0)).toStringAsFixed(2)}',
//                   style: const TextStyle(
//                     color: kTextDark,
//                     fontSize: 13.5,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//             if (item != previewItems.last) const SizedBox(height: 12),
//           ],
//           if (selectedItems.length > previewItems.length) ...[
//             const SizedBox(height: 14),
//             Text(
//               '+${selectedItems.length - previewItems.length} more item(s)',
//               style: TextStyle(
//                 color: _accent,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _summaryRow({
//     required IconData icon,
//     required String label,
//     required String value,
//     required Color accent,
//   }) {
//     return Row(
//       children: [
//         Container(
//           width: 38,
//           height: 38,
//           decoration: BoxDecoration(
//             color: accent.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(icon, color: accent, size: 18),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(
//             label,
//             style: const TextStyle(
//               color: kTextMuted,
//               fontSize: 13.5,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         Flexible(
//           child: Text(
//             value,
//             textAlign: TextAlign.right,
//             style: const TextStyle(
//               color: kTextDark,
//               fontSize: 14,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String get _resolvedAddressText {
//     if (address == null) return '';

//     final List<String> lines = [];
//     final fullName = [
//       address!['first_name']?.toString() ?? '',
//       address!['last_name']?.toString() ?? '',
//     ].where((part) => part.trim().isNotEmpty).join(' ');
//     if (fullName.isNotEmpty) lines.add(fullName);

//     for (final key in const ['address_line_1', 'address_line_2']) {
//       final value = address![key]?.toString() ?? '';
//       if (value.trim().isNotEmpty) lines.add(value.trim());
//     }

//     final cityStatePostal = [
//       address!['city']?.toString() ?? '',
//       address!['state']?.toString() ?? '',
//       address!['postal_code']?.toString() ?? '',
//     ].where((part) => part.trim().isNotEmpty).join(', ');
//     if (cityStatePostal.isNotEmpty) lines.add(cityStatePostal);

//     final country = address!['country']?.toString() ?? '';
//     if (country.trim().isNotEmpty) lines.add(country.trim());

//     return lines.join('\n');
//   }
// }


import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/razorpay_service.dart';
import 'payment_success_page.dart';
import 'payment_failed_page.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);
const Color kSurface = Color(0xFFF7F7F7);
const Color kBorder = Color(0xFFEAEAEA);

class CheckoutPage extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> selectedItems;
  final bool promoApplied;
  final double deliveryFee;
  final double discountPercent;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.selectedItems,
    required this.promoApplied,
    required this.deliveryFee,
    required this.discountPercent,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const String _razorpayKeyId = 'rzp_test_Sjf5R4l0R8Ah9G';

  final RazorpayService _razorpayService = RazorpayService();

  List<Map<String, dynamic>> _savedAddresses = [];
  bool _isLoadingAddresses = true;
  int? _selectedAddressId;
  bool _showAddressForm = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  static const List<String> _countries = ['India', 'United States', 'Canada'];
  static const Map<String, List<String>> _statesByCountry = {
    'India': [
      'Tamil Nadu',
      'Karnataka',
      'Kerala',
      'Maharashtra',
      'Delhi',
      'Telangana',
    ],
    'United States': [
      'California',
      'Texas',
      'New York',
      'Florida',
      'Washington',
    ],
    'Canada': ['Ontario', 'British Columbia', 'Quebec', 'Alberta'],
  };
  static const List<String> _addressTypes = ['home', 'office', 'other'];

  String _selectedCountry = 'India';
  String? _selectedState = 'Tamil Nadu';
  String _selectedAddressType = 'home';
  String _paymentMethod = 'upi';
  bool _isPlacingOrder = false;
  bool _isSavingAddress = false;

  @override
  void initState() {
    super.initState();
    _razorpayService.init(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
    );
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _razorpayService.clear();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  // ─── Razorpay Event Handlers ──────────────────────────────────────────────

  void _handlePaymentSuccess(String paymentId) {
    debugPrint('✅ Razorpay Payment Success: $paymentId');
    if (!mounted) return;
    _submitOrderToBackend(paymentId: paymentId);
  }

  void _handlePaymentError(String message, bool isCancelled) {
    debugPrint('❌ Razorpay Payment Error: $message');
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentFailedPage(
          title: isCancelled ? 'Payment Cancelled' : 'Payment Failed',
          message: isCancelled
              ? 'No amount was charged. You can review the order and try again whenever you are ready.'
              : message,
          amount: total,
          itemsCount: _itemsCount,
          paymentMethodLabel: _paymentMethodLabel,
          address: _selectedAddress,
          selectedItems: widget.selectedItems,
          isCancelled: isCancelled,
          onTryAgain: () {
            Navigator.of(context).pop();
          },
          onBack: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  // ─── Open Razorpay Checkout ───────────────────────────────────────────────

  void _openRazorpayCheckout() {
    final int amountInPaise = (total * 100).round();
    final options = <String, dynamic>{
      'key': _razorpayKeyId,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': 'WSS Sports Academy',
      'description': 'Order Payment',
      'theme': {'color': '#E4252A'},
      'prefill': {
        'contact': '9163612345',
        'email': 'user@gmail.com',
      },
      'external': {
        'wallets': ['paytm', 'phonepe'],
      },
    };

    try {
      _razorpayService.open(options);
    } catch (e) {
      debugPrint('Razorpay open error: $e');
      setState(() => _isPlacingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payment gateway: $e')),
        );
      }
    }
  }

  // ─── Submit Order to Backend ─────────────────────────────────────────────

  Future<void> _submitOrderToBackend({String? paymentId}) async {
    setState(() => _isPlacingOrder = true);

    final result = await ApiService.checkoutCart(
      userId: widget.userId,
      productIds: widget.selectedItems
          .map<int>((item) => item['product_id'] as int)
          .toList(),
      addressId: _selectedAddressId,
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    if (result['success'] == true) {
      final payload = result['data'];
      Map<String, dynamic>? order;
      if (payload is Map && payload['order'] is Map) {
        order = Map<String, dynamic>.from(payload['order'] as Map);
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            title: _paymentMethod == 'cod'
                ? 'Order Confirmed'
                : 'Payment Successful',
            subtitle: _paymentMethod == 'cod'
                ? 'Pay at your doorstep'
                : 'Successfully Paid',
            amount: _readAmount(order?['total_amount']),
            itemPrice: subtotal,
            deliveryFee: widget.deliveryFee,
            discount: widget.promoApplied
                ? (subtotal * widget.discountPercent / 100)
                : 0.0,
            itemsCount: _readCount(order?['total_items']),
            paymentMethodLabel: _paymentMethodLabel,
            paymentId: paymentId,
            orderId: order?['id']?.toString(),
            address: order ?? _selectedAddress,
            selectedItems: widget.selectedItems,
            onContinueShopping: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    } else {
      final bool paymentWasCaptured = paymentId != null && paymentId.isNotEmpty;
      final String errorMessage =
          result['error']?.toString() ?? 'Failed to place order';

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentFailedPage(
            title: paymentWasCaptured ? 'Payment Received' : 'Order Failed',
            message: paymentWasCaptured
                ? 'Your payment went through, but we could not confirm the order. Please keep this payment ID for support.'
                : errorMessage,
            amount: total,
            itemsCount: _itemsCount,
            paymentMethodLabel: _paymentMethodLabel,
            paymentId: paymentId,
            address: _selectedAddress,
            selectedItems: widget.selectedItems,
            isCancelled: false,
            onTryAgain: () => Navigator.of(context).pop(),
            onBack: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  // ─── Place Order Entry Point ──────────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null && !_showAddressForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    if (_showAddressForm) {
      await _saveNewAddress();
      if (_selectedAddressId == null) return;
    }

    setState(() => _isPlacingOrder = true);

    if (_paymentMethod == 'cod') {
      await _submitOrderToBackend();
    } else {
      _openRazorpayCheckout();
    }
  }

  // ─── Address ─────────────────────────────────────────────────────────────

  Future<void> _loadSavedAddresses() async {
    setState(() => _isLoadingAddresses = true);
    final result = await ApiService.getUserAddresses(widget.userId);
    if (!mounted) return;
    setState(() {
      _isLoadingAddresses = false;
      if (result['addresses'] != null) {
        _savedAddresses = List<Map<String, dynamic>>.from(result['addresses']);
        if (_savedAddresses.isNotEmpty) {
          final defaultAddress = _savedAddresses.firstWhere(
            (addr) => addr['is_default'] == true,
            orElse: () => _savedAddresses.first,
          );
          _selectedAddressId = defaultAddress['id'];
        } else {
          _showAddressForm = true;
        }
      }
    });
  }

  List<String> get _stateOptions =>
      _statesByCountry[_selectedCountry] ?? const <String>[];

  double get subtotal => widget.selectedItems.fold(
        0.0,
        (sum, item) =>
            sum + ((item['price'] as num) * (item['quantity'] as num)),
      );

  double get total =>
      subtotal +
      widget.deliveryFee -
      (subtotal * widget.discountPercent / 100);

  Future<void> _saveNewAddress() async {
    if (!_formKey.currentState!.validate() || _selectedState == null) {
      if (_selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a state / province')),
        );
      }
      return;
    }
    setState(() => _isSavingAddress = true);
    final result = await ApiService.createAddress(
      userId: widget.userId,
      addressData: {
        'address_type': _selectedAddressType,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'address_line_1': _addressLine1Controller.text.trim(),
        'address_line_2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState,
        'postal_code': _postalCodeController.text.trim(),
        'country': _selectedCountry,
        'is_default': _savedAddresses.isEmpty,
      },
    );
    if (!mounted) return;
    setState(() => _isSavingAddress = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully'),
          backgroundColor: Color(0xFF1DB954),
        ),
      );
      _clearForm();
      await _loadSavedAddresses();
      setState(() => _showAddressForm = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error']?.toString() ?? 'Failed to save address',
          ),
        ),
      );
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _postalCodeController.clear();
    setState(() {
      _selectedCountry = 'India';
      _selectedState = 'Tamil Nadu';
      _selectedAddressType = 'home';
    });
  }

  Map<String, dynamic>? get _selectedAddress {
    if (_selectedAddressId == null) return null;
    for (final address in _savedAddresses) {
      if (address['id'] == _selectedAddressId) {
        return Map<String, dynamic>.from(address);
      }
    }
    return null;
  }

  int get _itemsCount => widget.selectedItems.fold<int>(
        0,
        (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
      );

  String get _paymentMethodLabel =>
      _paymentMethod == 'cod' ? 'Cash on Delivery' : 'UPI / Card';

  double _readAmount(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? total;

  int _readCount(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? _itemsCount;

  Future<void> _confirmDeleteAddress(int addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Address'),
        content:
            const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await ApiService.deleteAddress(
        addressId: addressId,
        userId: widget.userId,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted'),
            backgroundColor: Color(0xFF1DB954),
          ),
        );
        await _loadSavedAddresses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?.toString() ?? 'Failed to delete address',
            ),
          ),
        );
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: kBrandRed,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAddressSection(),
                  const SizedBox(height: 16),
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 16),
                  _buildPaymentSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildPlaceOrderBar(),
          ],
        ),
      ),
    );
  }

  // ─── Order Summary Card ───────────────────────────────────────────────────

  Widget _buildOrderSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBrandRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long, color: kBrandRed, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    color: kTextDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...widget.selectedItems.map((item) => _buildItemRow(item)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(color: kBorder),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                _summaryRow(
                    'Delivery Fee', '₹${widget.deliveryFee.toStringAsFixed(2)}'),
                if (widget.promoApplied)
                  _summaryRow(
                      'Discount', '-${widget.discountPercent.toInt()}%',
                      isDiscount: true),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: kBrandRed.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: kTextDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: kBrandRed,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item['image'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_outlined,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item['quantity']}',
                  style: const TextStyle(color: kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₹${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: kTextDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment Section ──────────────────────────────────────────────────────

  Widget _buildPaymentSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payment, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    color: kTextDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            value: 'upi',
            title: 'UPI / Card',
            subtitle: 'Pay securely via Razorpay',
            icon: Icons.credit_card_rounded,
            iconColor: const Color(0xFF6C63FF),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(color: kBorder, height: 1),
          ),
          _buildPaymentOption(
            value: 'cod',
            title: 'Cash on Delivery',
            subtitle: 'Pay when the order arrives',
            icon: Icons.local_shipping_rounded,
            iconColor: Colors.green,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? iconColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? iconColor : kTextDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: kTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? iconColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? iconColor : kBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Place Order Bar ──────────────────────────────────────────────────────

  Widget _buildPlaceOrderBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isPlacingOrder
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _paymentMethod == 'cod'
                          ? Icons.local_shipping_rounded
                          : Icons.lock_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _paymentMethod == 'cod'
                          ? 'Place Order • ₹${total.toStringAsFixed(2)}'
                          : 'Pay ₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Address Section ──────────────────────────────────────────────────────

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.location_on, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    color: kTextDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _isLoadingAddresses
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: kBrandRed),
                    ),
                  )
                : Column(
                    children: [
                      if (_savedAddresses.isNotEmpty && !_showAddressForm)
                        ..._savedAddresses.map(_buildAddressCard),
                      if (!_showAddressForm)
                        InkWell(
                          onTap: () => setState(() {
                            _showAddressForm = true;
                            _selectedAddressId = null;
                          }),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: kBrandRed.withOpacity(0.3), width: 1.5),
                              borderRadius: BorderRadius.circular(14),
                              color: kBrandRed.withOpacity(0.02),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline,
                                    color: kBrandRed, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Add New Address',
                                  style: TextStyle(
                                    color: kBrandRed,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_showAddressForm) _buildAddressForm(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final isSelected = _selectedAddressId == address['id'];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? kBrandRed : kBorder,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
        color: isSelected ? kBrandRed.withOpacity(0.04) : Colors.white,
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedAddressId = address['id'];
          _showAddressForm = false;
        }),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kBrandRed : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? kBrandRed : kBorder,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _tag(
                            address['address_type'].toString().toUpperCase(),
                            kBrandRed),
                        if (address['is_default'] == true) ...[
                          const SizedBox(width: 6),
                          _tag('DEFAULT', Colors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${address['first_name']} ${address['last_name']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${address['address_line_1']}, ${address['city']}, ${address['state']}',
                      style:
                          const TextStyle(fontSize: 12, color: kTextMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: () => _confirmDeleteAddress(address['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              if (_savedAddresses.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _showAddressForm = false;
                    _clearForm();
                    if (_savedAddresses.isNotEmpty) {
                      _selectedAddressId = _savedAddresses.first['id'];
                    }
                  }),
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdownField<String>(
            value: _selectedAddressType,
            label: 'Address Type',
            items: _addressTypes,
            onChanged: (value) {
              if (value != null) setState(() => _selectedAddressType = value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Required',
                  validator: _requiredValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Required',
                  validator: _requiredValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine1Controller,
            label: 'Address Line 1',
            hint: 'Street address, P.O. box',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine2Controller,
            label: 'Address Line 2',
            hint: 'Apartment, suite, unit',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            hint: 'Required',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<String>(
                  value: _selectedState,
                  label: 'State / Province',
                  items: _stateOptions,
                  onChanged: (value) =>
                      setState(() => _selectedState = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _postalCodeController,
                  label: 'Postal Code',
                  hint: 'Required',
                  validator: _requiredValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdownField<String>(
            value: _selectedCountry,
            label: 'Country',
            items: _countries,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCountry = value;
                  final nextStates =
                      _statesByCountry[_selectedCountry] ?? const [];
                  _selectedState =
                      nextStates.isNotEmpty ? nextStates.first : null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSavingAddress ? null : _saveNewAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSavingAddress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Save Address',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: kSurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBrandRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: kSurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBrandRed, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: kTextMuted, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDiscount ? Colors.green : kTextDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }
}