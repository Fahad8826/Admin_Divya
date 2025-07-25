import 'package:admin/Controller/complaint_details_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ComplaintDetailPage extends StatelessWidget {
  final Map<String, dynamic> complaintData;

  const ComplaintDetailPage({super.key, required this.complaintData});

  // Define a consistent and professional color palette
  static const Color _primaryColor = Color(
    0xFFD13443,
  ); // A solid red for primary accents
  static const Color _accentColor = Color(
    0xFFD32F2F,
  ); // A strong red for warnings/high priority
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
  static const Color _dividerColor = Color(
    0xFFE0E0E0,
  ); // Consistent divider color
  static const Color _successColor = Colors.green; // For 'resolved' status
  static const Color _warningColor = Colors.orange; // For 'in-progress' status
  static const Color _infoColor = Colors.blue; // For 'pending' status

  @override
  Widget build(BuildContext context) {
    // Initialize GetX controller
    final controller = Get.put(ComplaintDetailController());
    controller.initializeData(complaintData);

    // Get screen width for responsive adjustments
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth * 0.04; // 4% of screen width
    final double cardPadding = screenWidth * 0.05; // 5% of screen width
    final double titleFontSize = screenWidth * 0.055; // Adjust title font size
    final double bodyFontSize = screenWidth * 0.038; // Adjust body font size
    final double smallFontSize =
        screenWidth * 0.03; // Adjust small text font size

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Complaint Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize:
                screenWidth * 0.045, // Smaller app bar title on smaller screens
            color: _textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: _cardColor,
        foregroundColor: _textColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          color: _textColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_outlined,
              size: 20,
              color: _textColor,
            ),
            onPressed: () => controller.update(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Complaint Overview Card
            _buildOverviewCard(
              controller,
              context,
              cardPadding,
              titleFontSize,
              bodyFontSize,
              smallFontSize,
            ),
            const SizedBox(height: 16),
            // Response Input Section
            _buildResponseSection(
              controller,
              context,
              cardPadding,
              titleFontSize,
              bodyFontSize,
              smallFontSize,
            ),
            const SizedBox(height: 16),
            // Timeline of Responses/Updates
            _buildTimelineSection(
              controller,
              context,
              cardPadding,
              titleFontSize,
              bodyFontSize,
              smallFontSize,
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets for Consistent Design ---

  Widget _buildSectionTitle(String title, double fontSize, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color ?? _textColor,
        ),
      ),
    );
  }

  Widget _buildDetailRowWithIcon(
    String label,
    String value,
    IconData icon,
    double bodyFontSize,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: bodyFontSize * 1.3,
            color: _lightTextColor,
          ), // Icon size relative to body font
          const SizedBox(width: 12),
          SizedBox(
            width: 90, // Slightly reduced fixed width for labels
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _lightTextColor,
                fontSize: bodyFontSize,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: bodyFontSize,
                color: _textColor,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // Widget to display priority as a pill
  Widget _buildPriorityPill(int priority, double smallFontSize) {
    Color color;
    String text;

    switch (priority) {
      case 1:
        color = _successColor;
        text = 'LOW';
        break;
      case 2:
        color = _warningColor;
        text = 'MEDIUM';
        break;
      case 3:
        color = _accentColor;
        text = 'HIGH';
        break;
      default:
        color = Colors.grey.shade500;
        text = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$text PRIORITY',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: smallFontSize * 0.9, // Even smaller font for the pill
        ),
      ),
    );
  }

  // Widget for complaint overview
  Widget _buildOverviewCard(
    ComplaintDetailController controller,
    BuildContext context,
    double cardPadding,
    double titleFontSize,
    double bodyFontSize,
    double smallFontSize,
  ) {
    final createdAt = complaintData['timestamp'] != null
        ? DateFormat(
            'MMM dd, yyyy, hh:mm a',
          ).format((complaintData['timestamp'] as Timestamp).toDate())
        : 'N/A';
    final priority = complaintData['priority'] ?? 1;

    return Card(
      color: _cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    complaintData['name'] ?? 'Unknown Customer',
                    style: TextStyle(
                      fontSize:
                          titleFontSize *
                          0.9, // Slightly smaller than main title
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _buildPriorityPill(priority, smallFontSize),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Complaint ID: ${complaintData['complaintId'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: smallFontSize,
                color: _lightTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 32, thickness: 1, color: _dividerColor),
            _buildDetailRowWithIcon(
              'Category',
              complaintData['category'] ?? 'N/A',
              Icons.category_outlined,
              bodyFontSize,
            ),
            _buildDetailRowWithIcon(
              'Email',
              complaintData['email'] ?? 'N/A',
              Icons.email_outlined,
              bodyFontSize,
            ),
            _buildDetailRowWithIcon(
              'User Role',
              complaintData['userRole'] ?? 'Unknown',
              Icons.assignment_ind_outlined,
              bodyFontSize,
            ),
            _buildDetailRowWithIcon(
              'Created At',
              createdAt,
              Icons.event_note_outlined,
              bodyFontSize,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Complaint Description', bodyFontSize * 1.1),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                bodyFontSize,
              ), // Padding relative to body font size
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                complaintData['complaint'] ?? 'No description provided.',
                style: TextStyle(
                  fontSize: bodyFontSize,
                  color: _textColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for response input section
  Widget _buildResponseSection(
    ComplaintDetailController controller,
    BuildContext context,
    double cardPadding,
    double titleFontSize,
    double bodyFontSize,
    double smallFontSize,
  ) {
    return Card(
      color: _cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Add Response',
              titleFontSize * 0.9,
              color: _primaryColor,
            ),
            const Divider(height: 24, thickness: 1, color: _dividerColor),
            const SizedBox(height: 12),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedStatus.value,
                decoration: InputDecoration(
                  labelText: 'Update Status',
                  labelStyle: TextStyle(
                    color: _lightTextColor,
                    fontSize: bodyFontSize,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: bodyFontSize,
                    vertical: bodyFontSize,
                  ),
                ),
                items: ['pending', 'in-progress', 'resolved']
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusTextColor(status),
                            fontWeight: FontWeight.w500,
                            fontSize: bodyFontSize,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => controller.selectedStatus.value = value!,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.responseController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Response Message',
                labelStyle: TextStyle(
                  color: _lightTextColor,
                  fontSize: bodyFontSize,
                ),
                hintText: 'Enter your response to this complaint...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: bodyFontSize,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primaryColor, width: 2),
                ),
                contentPadding: EdgeInsets.all(bodyFontSize),
              ),
              style: TextStyle(color: _textColor, fontSize: bodyFontSize),
            ),
            const SizedBox(height: 24),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.submitResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: bodyFontSize + 4,
                    ), // Adjusted padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit Response',
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for previous responses/timeline section
  Widget _buildTimelineSection(
    ComplaintDetailController controller,
    BuildContext context,
    double cardPadding,
    double titleFontSize,
    double bodyFontSize,
    double smallFontSize,
  ) {
    return Card(
      color: _cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Response History',
              titleFontSize * 0.9,
              color: Colors.blue.shade700,
            ),
            const Divider(height: 24, thickness: 1, color: _dividerColor),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: controller.firestore
                  .collection('complaint_responses')
                  .where('complaintId', isEqualTo: complaintData['complaintId'])
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: CircularProgressIndicator(color: _primaryColor),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: _accentColor),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'No responses yet.',
                        style: TextStyle(
                          color: _lightTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] != null
                        ? DateFormat(
                            'MMM dd, yyyy, hh:mm a',
                          ).format((data['timestamp'] as Timestamp).toDate())
                        : 'N/A';
                    final newStatus = data['newStatus']?.toString() ?? 'N/A';

                    return _buildTimelineEntry(
                      context,
                      timestamp,
                      data['response'] ?? 'No response text',
                      newStatus,
                      bodyFontSize,
                      smallFontSize,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper for status text color in dropdown
  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _infoColor;
      case 'in-progress':
        return _warningColor;
      case 'resolved':
        return _successColor;
      default:
        return _textColor;
    }
  }

  // A new widget to represent a single timeline entry
  Widget _buildTimelineEntry(
    BuildContext context,
    String timestamp,
    String responseText,
    String newStatus,
    double bodyFontSize,
    double smallFontSize,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(
        bodyFontSize,
      ), // Padding relative to body font size
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_toggle_off_outlined,
                size: bodyFontSize * 1.2,
                color: _primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                timestamp,
                style: TextStyle(
                  fontSize: smallFontSize,
                  color: _lightTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (newStatus != 'N/A')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ), // Reduced padding
                  decoration: BoxDecoration(
                    color: _getStatusTextColor(newStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusTextColor(newStatus).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    newStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize:
                          smallFontSize *
                          0.9, // Even smaller font for status chip
                      fontWeight: FontWeight.w600,
                      color: _getStatusTextColor(newStatus),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            responseText,
            style: TextStyle(
              fontSize: bodyFontSize,
              color: _textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
