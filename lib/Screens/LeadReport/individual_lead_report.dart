// import 'package:admin/Controller/lead_report_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// class LeadDetailPage extends StatelessWidget {
//   final Map<String, dynamic> lead;

//   LeadDetailPage({super.key, required this.lead});

//   final controller = Get.put(LeadReportController());

//   Color _getStatusColor(String status) {
//     switch (status.toUpperCase()) {
//       case 'HOT':
//         return Colors.red;
//       case 'WARM':
//         return Colors.orange;
//       case 'COLD':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           lead['name'] ?? 'Lead Details',
//           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.grey[900],
//         elevation: 1,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Main Lead Card
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Header with name and status
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             lead['name'] ?? 'N/A',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         Row(
//                           children: [
//                             if (lead['isArchived'] == true)
//                               Container(
//                                 margin: const EdgeInsets.only(right: 8),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red.shade100,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Text(
//                                   'ARCHIVED',
//                                   style: TextStyle(
//                                     color: Colors.red,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 10,
//                                   ),
//                                 ),
//                               ),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                                 vertical: 5,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: _getStatusColor(lead['status'] ?? ''),
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               child: Text(
//                                 lead['status'] ?? 'N/A',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 16),

//                     // Details in a clean list format
//                     _buildDetailRow('Customer ID', lead['customerId'] ?? 'N/A'),
//                     _buildDetailRow('Lead ID', lead['leadId'] ?? 'N/A'),
//                     _buildDetailRow('Primary Phone', lead['phone1'] ?? 'N/A'),

//                     if (lead['phone2'] != null &&
//                         lead['phone2'].toString().isNotEmpty)
//                       _buildDetailRow('Secondary Phone', lead['phone2']),

//                     _buildDetailRow('Address', lead['address'] ?? 'N/A'),
//                     _buildDetailRow('Place', lead['place'] ?? 'N/A'),
//                     _buildDetailRow('Product ID', lead['productID'] ?? 'N/A'),
//                     _buildDetailRow('Salesman', lead['salesman'] ?? 'N/A'),
//                     _buildDetailRow(
//                       'Numbers',
//                       lead['nos']?.toString() ?? 'N/A',
//                     ),

//                     _buildDetailRow(
//                       'Created Date',
//                       lead['createdAt'] != null
//                           ? DateFormat(
//                               'MMM dd, yyyy - HH:mm',
//                             ).format(lead['createdAt'])
//                           : 'N/A',
//                     ),

//                     _buildDetailRow(
//                       'Follow Up Date',
//                       lead['followUpDate'] != null
//                           ? DateFormat(
//                               'MMM dd, yyyy - HH:mm',
//                             ).format(lead['followUpDate'])
//                           : 'N/A',
//                     ),

//                     // Remarks section
//                     if (lead['remark'] != null &&
//                         lead['remark'].toString().isNotEmpty) ...[
//                       const SizedBox(height: 8),
//                       const Divider(),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Remarks',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey[700],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[50],
//                           borderRadius: BorderRadius.circular(6),
//                           border: Border.all(color: Colors.grey[200]!),
//                         ),
//                         child: Text(
//                           lead['remark'],
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 110,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// Individual Lead Detail Page

import 'package:admin/Controller/lead_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LeadDetailPage extends StatelessWidget {
  final Map<String, dynamic> lead;

  LeadDetailPage({super.key, required this.lead});

  // Define a consistent and professional color palette
  static const Color _primaryColor = Color(
    0xFF1976D2,
  ); // A solid blue for primary accents
  static const Color _accentColor = Color(
    0xFFD32F2F,
  ); // A strong red for "HOT" and warnings
  static const Color _textColor = Color(
    0xFF212121,
  ); // Very dark grey for main text
  static const Color _lightTextColor = Color(
    0xFF616161,
  ); // Medium grey for labels and secondary text
  static const Color _cardColor =
      Colors.white; // Pure white for card backgrounds
  static const Color _backgroundColor = Color(
    0xFFF0F2F5,
  ); // Light off-white for scaffold background

  final controller = Get.put(LeadReportController());

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'HOT':
        return _accentColor;
      case 'WARM':
        return Colors.amber.shade700; // Deeper amber
      case 'COOL':
        return _primaryColor.withOpacity(0.9); // Slightly darker blue

      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Apply the light off-white background
      appBar: AppBar(
        title: Text(
          lead['name'] ?? 'Lead Details',
          style: const TextStyle(
            fontWeight: FontWeight.w700, // Stronger weight for app bar title
            fontSize: 19,
            color: _textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: _cardColor, // White app bar background
        foregroundColor: _textColor, // Icons and text use the main text color
        elevation: 2, // Subtle shadow for app bar
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ), // Modern back icon
          onPressed: () => Navigator.of(context).pop(),
          color: _textColor, // Icon color matches text
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: _primaryColor,
              size: 22,
            ), // Primary blue for action icon
            onPressed: () {
              // Action for editing lead
              Get.snackbar(
                'Edit Lead',
                'Edit functionality will be implemented here.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: _primaryColor,
                colorText: _cardColor,
                margin: const EdgeInsets.all(16),
                borderRadius: 8,
              );
            },
            tooltip: 'Edit Lead',
          ),
          const SizedBox(width: 8), // Padding on the right
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch card horizontally
          children: [
            // Main Lead Detail Card
            Card(
              color: _cardColor, // Pure white card background
              elevation: 5, // A bit more elevation for prominence
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  15,
                ), // Softer, more modern rounded corners
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                  24.0,
                ), // Generous padding inside the card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Lead Name and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Align top for multi-line names
                      children: [
                        Expanded(
                          child: Text(
                            lead['name'] ?? 'Unknown Lead',
                            style: const TextStyle(
                              fontSize: 26, // Larger and more prominent name
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                              height: 1.2, // Good line height for readability
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2, // Allow name to wrap
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildStatusPill(lead['status']),
                      ],
                    ),
                    const SizedBox(height: 16), // Space after name/status
                    // Customer ID & Lead ID as Chips/Tags
                    Wrap(
                      spacing: 12.0, // Horizontal space between chips
                      runSpacing: 8.0, // Vertical space if chips wrap
                      children: [
                        _buildInfoChip(
                          label: 'Customer ID',
                          value: lead['customerId'] ?? 'N/A',
                          icon: Icons.person_outline,
                        ),
                        _buildInfoChip(
                          label: 'Lead ID',
                          value: lead['leadId'] ?? 'N/A',
                          icon: Icons.tag_outlined,
                        ),
                        if (lead['isArchived'] == true) _buildArchivedTag(),
                      ],
                    ),

                    const Divider(
                      height: 32,
                      thickness: 1,
                      color: Color(0xFFE0E0E0),
                    ), // Subtle divider
                    // Section for Contact & Business Details
                    _buildSectionTitle('Contact & Business Information'),
                    const SizedBox(height: 12),
                    _buildDetailRowWithIcon(
                      'Primary Phone',
                      lead['phone1'] ?? 'N/A',
                      Icons.phone_outlined,
                    ),
                    if (lead['phone2'] != null &&
                        lead['phone2'].toString().isNotEmpty)
                      _buildDetailRowWithIcon(
                        'Secondary Phone',
                        lead['phone2'],
                        Icons.phone_android_outlined,
                      ),
                    _buildDetailRowWithIcon(
                      'Address',
                      lead['address'] ?? 'N/A',
                      Icons.location_on_outlined,
                    ),
                    _buildDetailRowWithIcon(
                      'Place',
                      lead['place'] ?? 'N/A',
                      Icons.place_outlined,
                    ),
                    _buildDetailRowWithIcon(
                      'Product ID',
                      lead['productID'] ?? 'N/A',
                      Icons.shopping_bag_outlined,
                    ),
                    _buildDetailRowWithIcon(
                      'Salesman',
                      lead['salesman'] ?? 'N/A',
                      Icons.person_outline,
                    ),
                    _buildDetailRowWithIcon(
                      'Quantity',
                      lead['nos']?.toString() ?? 'N/A',
                      Icons.format_list_numbered_rtl_outlined,
                    ),

                    const Divider(
                      height: 32,
                      thickness: 1,
                      color: Color(0xFFE0E0E0),
                    ), // Subtle divider
                    // Section for Timeline
                    _buildSectionTitle('Timeline'),
                    const SizedBox(height: 12),
                    _buildDetailRowWithIcon(
                      'Created On',
                      lead['createdAt'] != null
                          ? DateFormat(
                              'MMM dd, yyyy, hh:mm a',
                            ).format(lead['createdAt'])
                          : 'N/A',
                      Icons.event_note_outlined,
                    ),
                    _buildDetailRowWithIcon(
                      'Follow Up On',
                      lead['followUpDate'] != null
                          ? DateFormat(
                              'MMM dd, yyyy, hh:mm a',
                            ).format(lead['followUpDate'])
                          : 'N/A',
                      Icons.schedule_outlined,
                    ),

                    // Remarks Section
                    if (lead['remark'] != null &&
                        lead['remark'].toString().isNotEmpty) ...[
                      const Divider(
                        height: 32,
                        thickness: 1,
                        color: Color(0xFFE0E0E0),
                      ), // Subtle divider
                      _buildSectionTitle('Remarks'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              _backgroundColor, // Use light grey for remarks background
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          lead['remark'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: _textColor,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets for Cleaner Code ---

  Widget _buildStatusPill(dynamic status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _getStatusColor(status ?? ''),
        borderRadius: BorderRadius.circular(20), // More pronounced pill shape
      ),
      child: Text(
        (status ?? 'N/A').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700, // Bolder text in pill
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor, // Use background color for chip fill
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ), // Light border for definition
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Keep chip content tight
        children: [
          Icon(icon, size: 16, color: _lightTextColor), // Smaller icon in chip
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _lightTextColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.shade50, // Very light red background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200), // Subtle red border
      ),
      child: const Text(
        'ARCHIVED',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5, // Slight letter spacing for impact
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _textColor, // Section titles are dark and bold
        ),
      ),
    );
  }

  Widget _buildDetailRowWithIcon(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // More vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: _primaryColor.withOpacity(0.8),
          ), // Primary color for detail icons
          const SizedBox(width: 12),
          SizedBox(
            width: 120, // Slightly wider fixed width for labels
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: _lightTextColor, // Lighter grey for labels
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: _textColor, // Main text color for values
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis, // Handle long values
              maxLines: 2, // Allow values to wrap
            ),
          ),
        ],
      ),
    );
  }
}
