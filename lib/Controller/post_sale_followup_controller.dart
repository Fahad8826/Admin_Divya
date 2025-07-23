

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:developer';

// Assume these exist or need to be implemented based on your project

class PostSaleFollowupController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Map<String, dynamic>> allOrders = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxBool isDataLoaded = false.obs;
  final RxList<String> availablePlaces = <String>[].obs;
  final RxList<String> availableSalespeople = <String>[].obs;

  DocumentSnapshot? _lastDocument;
  final int itemsPerPage = 10;

  // Filter variables
  final RxString searchQuery = ''.obs;
  final RxString placeFilter = ''.obs;
  final RxString salespersonFilter = ''.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  // Pagination for filtered data (for display)
  final RxList<Map<String, dynamic>> filteredOrders =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> paginatedOrders =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingMore = false.obs;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
    // Add listeners for filter changes to re-filter orders
    everAll([searchQuery, placeFilter, salespersonFilter, startDate, endDate], (
      _,
    ) {
      filterOrders();
    });

    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent &&
        !isLoading.value &&
        hasMoreData.value &&
        !isLoadingMore.value) {
      log('Reached end of list, loading more...');
      fetchOrders();
    }
  }

  Future<String> getSalesmanName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'N/A';
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final name = doc.data()?['name'];
        return name ?? 'Unknown';
      } else {
        return 'Not Found';
      }
    } catch (e) {
      log('Error fetching user for $uid: $e');
      return 'Error';
    }
  }

  Future<String> getmakerName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'N/A';
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final name = doc.data()?['name'];
        return name ?? 'Unknown';
      } else {
        return 'Not Found';
      }
    } catch (e) {
      log('Error fetching user for $uid: $e');
      return 'Error';
    }
  }

  /// Fetches a paginated list of delivered orders from Firestore.
  ///
  /// Set `isRefresh` to `true` to clear existing data and start from the beginning.
  Future<void> fetchOrders({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _lastDocument = null;
        allOrders.clear();
        hasMoreData.value = true;
        isDataLoaded.value = false; // Reset data loaded flag
      }

      if (!hasMoreData.value || isLoading.value || isLoadingMore.value) {
        return; // Prevent multiple simultaneous fetches
      }

      if (allOrders.isEmpty) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection('Orders')
          .orderBy('createdAt', descending: true)
          .where('order_status', isEqualTo: 'delivered')
          .limit(itemsPerPage);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot<Map<String, dynamic>> orderSnapshot = await query.get();

      if (orderSnapshot.docs.isEmpty) {
        hasMoreData.value = false;
        isLoading.value = false;
        isLoadingMore.value = false;
        if (allOrders.isEmpty) {
          isDataLoaded.value = true; // No data, but finished loading
        }
        return;
      }

      List<Map<String, dynamic>> tempOrders = [];
      Set<String> placesSet = <String>{};
      Set<String> salespeopleSet = <String>{};

      for (var doc in orderSnapshot.docs) {
        final data = doc.data();
        final String? salesmanID = data['salesmanID'];
        final String salesmanName = await getSalesmanName(salesmanID);
        final String? makerID = data['makerId'];
        final String maker = await getmakerName(makerID);

        tempOrders.add({
          'address': data['address'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'deliveryDate': (data['deliveryDate'] as Timestamp?)?.toDate(),
          'followUpDate': (data['followUpDate'] as Timestamp?)?.toDate(),
          'makerId': data['makerId'] ?? '',
          'name': data['name'] ?? '',
          'nos': data['nos'] ?? 0,
          'orderId': data['orderId'] ?? '',
          'order_status': data['order_status'] ?? '',
          'phone1': data['phone1'] ?? '',
          'phone2': data['phone2'] ?? '',
          'place': data['place'] ?? '',
          'productID': data['productID'] ?? '',
          'remark': data['remark'] ?? '',
          'salesman': salesmanName,
          'maker': maker,
          'followUpNotes': data['followUpNotes'] ?? '',
        });

        final place = data['place']?.toString().trim();
        if (place != null && place.isNotEmpty) {
          placesSet.add(place);
        }
        if (salesmanName.isNotEmpty && salesmanName != 'N/A') {
          salespeopleSet.add(salesmanName);
        }
      }

      _lastDocument = orderSnapshot.docs.last;
      allOrders.addAll(tempOrders);

      // Only update available filters if refreshing or if they are empty
      if (isRefresh || availablePlaces.isEmpty) {
        availablePlaces.value = placesSet.toList()..sort();
        availableSalespeople.value = salespeopleSet.toList()..sort();
      }

      filterOrders();
      isDataLoaded.value = true;
    } catch (e) {
      log('Error fetching orders: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch orders: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void filterOrders() {
    List<Map<String, dynamic>> tempFilteredOrders = allOrders.where((order) {
      final String name = order['name']?.toString().toLowerCase() ?? '';
      final String orderId = order['orderId']?.toString().toLowerCase() ?? '';
      final String place = order['place']?.toString().toLowerCase() ?? '';
      final String salesman = order['salesman']?.toString().toLowerCase() ?? '';

      final String query = searchQuery.value.toLowerCase();
      final bool matchesSearch =
          name.contains(query) || orderId.contains(query);

      final bool matchesPlace =
          placeFilter.value.isEmpty ||
          placeFilter.value == 'All' ||
          place == placeFilter.value.toLowerCase();

      final bool matchesSalesperson =
          salespersonFilter.value.isEmpty ||
          salespersonFilter.value == 'All' ||
          salesman == salespersonFilter.value.toLowerCase();

      final DateTime? orderDeliveryDate = order['deliveryDate'] as DateTime?;
      final bool matchesDateRange =
          startDate.value == null ||
          (orderDeliveryDate != null &&
              orderDeliveryDate.isAfter(startDate.value!) &&
              orderDeliveryDate.isBefore(
                endDate.value!.add(const Duration(days: 1)),
              )); // Include end day

      return matchesSearch &&
          matchesPlace &&
          matchesSalesperson &&
          matchesDateRange;
    }).toList();

    filteredOrders.value = tempFilteredOrders;
    paginatedOrders.value =
        tempFilteredOrders; 
  }

  void setPlaceFilter(String? value) {
    placeFilter.value = value ?? '';
  }

  void setSalespersonFilter(String? value) {
    salespersonFilter.value = value ?? '';
  }

  void setDateRange(DateTimeRange? range) {
    startDate.value = range?.start;
    endDate.value = range?.end;
  }

  void clearFilters() {
    searchQuery.value = '';
    placeFilter.value = '';
    salespersonFilter.value = '';
    startDate.value = null;
    endDate.value = null;
    // No need to call filterOrders() here, as the Rx variables will trigger it.
  }

  Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade100;
      case 'pending':
        return Colors.orange.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color getOrderStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade800;
      case 'pending':
        return Colors.orange.shade800;
      case 'cancelled':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  /// Fetches all "delivered" orders from Firestore, applying current filters.
  /// This method is designed to retrieve all relevant data for generating reports,
  /// bypassing pagination to ensure a complete dataset based on active filters.
  Future<List<Map<String, dynamic>>> _getFilteredOrdersDataForReport() async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('Orders')
          .where('order_status', isEqualTo: 'delivered')
          .orderBy('createdAt', descending: true); // Initial ordering

      // Apply filters from controller's Rx variables
      if (placeFilter.value.isNotEmpty && placeFilter.value != 'All') {
        query = query.where('place', isEqualTo: placeFilter.value);
      }
      if (salespersonFilter.value.isNotEmpty &&
          salespersonFilter.value != 'All') {
        // NOTE: This assumes 'salesman' field in Firestore stores the name directly.
        // If it stores salesmanID, you'd need a different approach (e.g., fetch all, then filter client-side,
        // or ensure salesmanID is consistently stored and filter by that).
        // For simplicity, assuming 'salesman' field holds the name for direct query.
        query = query.where('salesman', isEqualTo: salespersonFilter.value);
      }
      if (startDate.value != null && endDate.value != null) {
        // Filter by createdAt timestamp (or deliveryDate, depending on report need)
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: startDate.value,
        );
        // Add one day to endDate to include orders on the exact end date
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: endDate.value!.add(const Duration(days: 1)),
        );
      }

      final QuerySnapshot<Map<String, dynamic>> orderSnapshot = await query
          .get();

      List<Map<String, dynamic>> fullOrdersData = [];
      for (var doc in orderSnapshot.docs) {
        final data = doc.data();
        final String? salesmanID = data['salesmanID'];
        final String salesmanName = await getSalesmanName(salesmanID);
        final String? makerID = data['makerId'];
        final String maker = await getmakerName(makerID);

        fullOrdersData.add({
          'address': data['address'] ?? '',
          'createdAt':
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'deliveryDate': (data['deliveryDate'] as Timestamp?)?.toDate(),
          'followUpDate': (data['followUpDate'] as Timestamp?)?.toDate(),
          'makerId': data['makerId'] ?? '',
          'name': data['name'] ?? '',
          'nos': data['nos'] ?? 0,
          'orderId': data['orderId'] ?? '',
          'order_status': data['order_status'] ?? '',
          'phone1': data['phone1'] ?? '',
          'phone2': data['phone2'] ?? '',
          'place': data['place'] ?? '',
          'productID': data['productID'] ?? '',
          'remark': data['remark'] ?? '',
          'salesman': salesmanName,
          'maker': maker,
          'followUpNotes': data['followUpNotes'] ?? '',
        });
      }
      return fullOrdersData;
    } catch (e) {
      log('Error fetching all orders for report with filters: $e');
      Get.snackbar(
        'Error',
        'Failed to retrieve orders for report: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return [];
    }
  }

  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
    } else {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
    }

    Get.snackbar(
      'Permission Required',
      'Storage permission required. Please enable it in settings.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      mainButton: TextButton(
        onPressed: openAppSettings,
        child: const Text(
          'Open Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );

    return false;
  }

  /// Generates an Excel file containing all delivered order data (based on current filters).
  Future<File> _generateOrdersExcelFile(
    List<Map<String, dynamic>> ordersData,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['All Orders Data'];

    // Set column widths for better readability
    sheet.setColumnWidth(0, 20); // Order ID
    sheet.setColumnWidth(1, 25); // Customer Name
    sheet.setColumnWidth(2, 15); // Phone 1
    sheet.setColumnWidth(3, 15); // Phone 2
    sheet.setColumnWidth(4, 30); // Address
    sheet.setColumnWidth(5, 15); // Place
    sheet.setColumnWidth(6, 10); // NOS (Number of items)
    sheet.setColumnWidth(7, 20); // Product ID
    sheet.setColumnWidth(8, 20); // Salesman
    sheet.setColumnWidth(9, 20); // Maker
    sheet.setColumnWidth(10, 20); // Order Status
    sheet.setColumnWidth(11, 20); // Created At
    sheet.setColumnWidth(12, 20); // Delivery Date
    sheet.setColumnWidth(13, 20); // Follow Up Date
    sheet.setColumnWidth(14, 30); // Remark
    sheet.setColumnWidth(15, 30); // Follow Up Notes

    // Define header row
    final headers = [
      'Order ID',
      'Customer Name',
      'Phone 1',
      'Phone 2',
      'Address',
      'Place',
      'NOS',
      'Product ID',
      'Salesman',
      'Maker',
      'Order Status',
      'Created At',
      'Delivery Date',
      'Follow Up Date',
      'Remark',
      'Follow Up Notes',
    ];

    // Add headers to the first row of the Excel sheet
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.blue200,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Populate data rows from the ordersData list
    for (int rowIndex = 0; rowIndex < ordersData.length; rowIndex++) {
      final order = ordersData[rowIndex];

      final rowData = [
        order['orderId'] ?? 'N/A',
        order['name'] ?? 'N/A',
        order['phone1'] ?? 'N/A',
        order['phone2'] ?? 'N/A',
        order['address'] ?? 'N/A',
        order['place'] ?? 'N/A',
        order['nos']?.toString() ?? 'N/A',
        order['productID'] ?? 'N/A',
        order['salesman'] ?? 'N/A',
        order['maker'] ?? 'N/A',
        order['order_status'] ?? 'N/A',
        (order['createdAt'] as DateTime?)?.toLocal().toString().split('.')[0] ??
            'N/A',
        (order['deliveryDate'] as DateTime?)?.toLocal().toString().split(
              '.',
            )[0] ??
            'N/A',
        (order['followUpDate'] as DateTime?)?.toLocal().toString().split(
              '.',
            )[0] ??
            'N/A',
        order['remark'] ?? 'N/A',
        order['followUpNotes'] ?? 'N/A',
      ];

      for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex + 1,
          ),
        );
        cell.value = TextCellValue(rowData[colIndex]);

        // Apply color coding to the 'Order Status' column
        if (colIndex == 10) {
          final status = order['order_status']?.toString().toLowerCase();
          if (status == 'delivered') {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.green200);
          } else if (status == 'pending') {
            cell.cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.orange200,
            );
          } else if (status == 'cancelled') {
            cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.red200);
          }
        }
      }
    }

    // Add a summary row for total orders
    final summaryRow = ordersData.length + 2;
    var summaryCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
    );
    summaryCell.value = TextCellValue('Total Orders: ${ordersData.length}');
    summaryCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.grey100,
    );

    // Add a timestamp for when the report was generated
    final timestampRow = summaryRow + 1;
    var timestampCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: timestampRow),
    );
    timestampCell.value = TextCellValue(
      'Generated on: ${DateTime.now().toLocal().toString().split('.')[0]}',
    );
    timestampCell.cellStyle = CellStyle(italic: true, fontSize: 10);

    // Save the Excel file to the application's documents directory
    final outputDir = await getApplicationDocumentsDirectory();
    final file = File(
      '${outputDir.path}/all_orders_data_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  /// Downloads all "delivered" order data as a PDF document (based on current filters).
  Future<void> downloadAllOrdersDataAsPDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      final ordersData =
          await _getFilteredOrdersDataForReport(); // Use filtered data

      if (ordersData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No orders found to download in PDF.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.portrait.copyWith(
            marginLeft: PdfPageFormat.mm / 4,
            marginRight: PdfPageFormat.mm / 4,
            marginTop: PdfPageFormat.mm / 4,
            marginBottom: PdfPageFormat.mm / 4,
          ), // Adjusted margins for more content space
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'All Delivered Orders Data',
                  style: pw.TextStyle(
                    fontSize: 20, // Slightly smaller font for header
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10), // Reduced spacing
              // Use a Table for better PDF presentation of tabular data
              pw.Table.fromTextArray(
                headers: [
                  'Order ID',
                  'Customer Name',
                  'Place',
                  'NOS',
                  'Salesman',
                  'Maker',
                  'Status',
                  'Created At',
                ],
                data: ordersData.map((order) {
                  return [
                    order['orderId'] ?? 'N/A',
                    order['name'] ?? 'N/A',
                    order['place'] ?? 'N/A',
                    order['nos']?.toString() ?? 'N/A',
                    order['salesman'] ?? 'N/A',
                    order['maker'] ?? 'N/A',
                    order['order_status'] ?? 'N/A',
                    (order['createdAt'] as DateTime?)
                            ?.toLocal()
                            .toString()
                            .split('.')[0] ??
                        'N/A',
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ), // Smaller header font
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(3), // Smaller cell padding
                cellStyle: const pw.TextStyle(fontSize: 7), // Smaller cell font
              ),
              pw.SizedBox(height: 15),
              pw.Text(
                'Total Orders: ${ordersData.length}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Generated on: ${DateTime.now().toLocal().toString().split('.')[0]}',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ];
          },
        ),
      );

      final outputDir = await getApplicationDocumentsDirectory();
      final fileName =
          'all_orders_data_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Generated'),
            content: Text(
              'PDF "$fileName" has been saved to app documents directory. Would you like to open it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (context.mounted) Navigator.of(context).pop();
                  final result = await OpenFile.open(file.path);
                  if (result.type != ResultType.done) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not open PDF: ${result.message}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Open'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error downloading orders PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Downloads all "delivered" order data as an Excel file (based on current filters).
  Future<void> downloadAllOrdersDataAsExcel(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating Excel...'),
          ],
        ),
      ),
    );

    try {
      final ordersData =
          await _getFilteredOrdersDataForReport(); // Use filtered data

      if (ordersData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No orders found to download in Excel.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final file = await _generateOrdersExcelFile(ordersData);
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excel Generated'),
            content: Text(
              'Excel file "${file.path.split('/').last}" has been saved to app documents directory. Would you like to open it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (context.mounted) Navigator.of(context).pop();
                  final result = await OpenFile.open(file.path);
                  if (result.type != ResultType.done) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not open Excel: ${result.message}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Open'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error generating Excel: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shares all "delivered" order data as an Excel file (based on current filters).
  Future<void> shareAllOrdersDataAsExcel(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Preparing Excel for sharing...'),
          ],
        ),
      ),
    );

    try {
      final ordersData =
          await _getFilteredOrdersDataForReport(); // Use filtered data

      if (ordersData.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No orders found to share.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final file = await _generateOrdersExcelFile(ordersData);
      if (context.mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'All Orders Data Report',
        subject:
            'Orders Data Export - ${DateTime.now().toLocal().toString().split(' ')[0]}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel file prepared for sharing'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      log('Error sharing Excel: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
