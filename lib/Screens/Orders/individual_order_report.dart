import 'package:admin/Controller/order_report_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class IndividualOrderReportPage extends StatelessWidget {
  final Map<String, dynamic> order;

  IndividualOrderReportPage({super.key, required this.order});

  final controller = Get.put(OrderReportController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[900],

        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (order['Cancel'] == true)
                        ? const Color.fromARGB(
                            255,
                            255,
                            111,
                            133,
                          ) // light reddish background if canceled
                        : Colors.white, // default background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              children: [
                                Text(
                                  order['name'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  order['customerId'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),

                          // Status Badges
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getOrderStatusColor(
                                    order['order_status'] ?? '',
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order['order_status'] ?? 'N/A',
                                  style: TextStyle(
                                    color: _getOrderStatusTextColor(
                                      order['order_status'] ?? '',
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Order ID: ${order['orderId'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Information
            _buildSectionCard('Contact Information', Icons.contact_page, [
              _buildDetailRow(
                Icons.location_on,
                'Place',
                order['place'] ?? 'N/A',
              ),
              _buildDetailRow(Icons.phone, 'Phone', order['phone1'] ?? 'N/A'),
              if (order['address'] != null &&
                  order['address'].toString().isNotEmpty)
                _buildDetailRow(Icons.home, 'Address', order['address']),
            ]),
            const SizedBox(height: 16),

            // Order Information
            _buildSectionCard('Order Information', Icons.inventory, [
              _buildDetailRow(
                Icons.inventory,
                'Product ID',
                order['productID'] ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.numbers,
                'Quantity',
                order['nos']?.toString() ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.person,
                'Salesman',
                order['salesman'] ?? 'N/A',
              ),
              _buildDetailRow(Icons.person, 'Maker', order['maker'] ?? 'N/A'),
            ]),
            const SizedBox(height: 16),

            // Dates Information
            _buildSectionCard('Dates', Icons.calendar_today, [
              _buildDetailRow(
                Icons.calendar_today,
                'Created',
                order['createdAt'] != null
                    ? DateFormat('MMM dd, yyyy').format(order['createdAt'])
                    : 'N/A',
              ),
              if (order['deliveryDate'] != null)
                _buildDetailRow(
                  Icons.local_shipping,
                  'Delivery Date',
                  DateFormat('MMM dd, yyyy').format(order['deliveryDate']),
                ),
            ]),
            const SizedBox(height: 16),

            // Additional Information
            if (order['remark'] != null &&
                order['remark'].toString().isNotEmpty)
              _buildSectionCard('Additional Information', Icons.note, [
                _buildDetailRow(Icons.note, 'Remark', order['remark']),
              ]),
            if (order['Cancel'] == true)
              _buildSectionCard('CANCEL', Icons.note, [
                _buildDetailRow(
                  Icons.note,
                  'Cancel',
                  'Cancelled',
                ), // Optional: convert bool to string
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Status color methods (replace with your controller methods)

  // Order status color methods(background)
  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.yellow.shade100;
      case 'accepted':
        return Colors.green.shade100;
      case 'sent out for delivery':
        return Colors.blue.shade100;
      case 'delivered':
        return Colors.teal.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getOrderStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey.shade800;
      case 'accepted':
        return Colors.green.shade800;
      case 'sent out for delivery':
        return Colors.blue.shade800;
      case 'delivered':
        return Colors.teal.shade800;
      default:
        return Colors.grey.shade800;
    }
  }
}
