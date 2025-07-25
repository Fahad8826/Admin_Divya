// import 'package:flutter/material.dart';
// import 'package:admin/Screens/Sales/salescontroller.dart';
// import 'package:admin/Screens/Sales/individual_user_details.dart';
// import 'package:admin/Screens/Users/addusers.dart';

// class SalesManagementPage extends StatelessWidget {
//   final SalesManagementController controller;

//   const SalesManagementPage({super.key, required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.grey[900],
//         title: const Text(
//           'Sales Management',
//           style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
//         ),
//         elevation: 0,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: controller.resetAndFetchUsers,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildSearchAndFilterBar(context, controller),
//           Expanded(
//             child: ValueListenableBuilder<List<Map<String, dynamic>>>(
//               valueListenable: controller.users,
//               builder: (context, users, _) {
//                 final filteredUsers = users.where((user) {
//                   final matchesFilter =
//                       controller.selectedFilter.value == 'all' ||
//                       (controller.selectedFilter.value == 'active' &&
//                           (user['isActive'] ?? true)) ||
//                       (controller.selectedFilter.value == 'inactive' &&
//                           !(user['isActive'] ?? true));

//                   final matchesSearch =
//                       controller.searchQuery.value.isEmpty ||
//                       (user['name']?.toLowerCase() ?? '').contains(
//                         controller.searchQuery.value.toLowerCase(),
//                       );

//                   return matchesFilter && matchesSearch;
//                 }).toList();

//                 if (filteredUsers.isEmpty) {
//                   return _buildEmptyState(context);
//                 }

//                 return _buildUserList(context, controller, filteredUsers);
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const AddUserPage()),
//         ),
//         backgroundColor: Color.fromARGB(255, 209, 52, 67),
//         foregroundColor: Colors.white,
//         icon: const Icon(Icons.person_add, size: 20),
//         label: const Text(
//           'Add Salesperson',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         elevation: 4,
//       ),
//     );
//   }

//   Widget _buildSearchAndFilterBar(
//     BuildContext context,
//     SalesManagementController controller,
//   ) {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.all(3),
//       child: Column(
//         children: [
//           SizedBox(
//             height: 54,
//             width: 300,
//             child: TextField(
//               controller: controller.searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search salespeople...',
//                 prefixIcon: Icon(
//                   Icons.search,
//                   color: Color.fromARGB(255, 209, 52, 67),
//                 ),
//                 suffixIcon: ValueListenableBuilder<String>(
//                   valueListenable: controller.searchQuery,
//                   builder: (context, query, _) => query.isNotEmpty
//                       ? IconButton(
//                           icon: Icon(
//                             Icons.clear,
//                             color: Color.fromARGB(255, 209, 52, 67),
//                           ),
//                           onPressed: () => controller.searchController.clear(),
//                         )
//                       : const SizedBox.shrink(),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[100],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.grey, width: 2),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           ValueListenableBuilder<String>(
//             valueListenable: controller.selectedFilter,
//             builder: (context, filter, _) => Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildFilterChip(controller, 'All', 'all', filter),
//                 _buildFilterChip(controller, 'Active', 'active', filter),
//                 _buildFilterChip(controller, 'Inactive', 'inactive', filter),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChip(
//     SalesManagementController controller,
//     String label,
//     String value,
//     String currentFilter,
//   ) {
//     return ChoiceChip(
//       label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
//       selected: currentFilter == value,
//       onSelected: (selected) => controller.updateFilter(value),
//       selectedColor: Color.fromARGB(255, 209, 52, 67),
//       backgroundColor: Colors.grey[100],
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//         side: BorderSide(color: Colors.white),
//       ),
//       labelStyle: TextStyle(
//         color: currentFilter == value ? Colors.white : Colors.grey[700],
//       ),
//     );
//   }

//   Widget _buildEmptyState(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'No Salespeople Found',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[700],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserList(
//     BuildContext context,
//     SalesManagementController controller,
//     List<Map<String, dynamic>> users,
//   ) {
//     return ListView.builder(
//       controller: controller.scrollController,
//       padding: const EdgeInsets.all(16),
//       itemCount: users.length + (controller.isLoadingMore.value ? 1 : 0),
//       itemBuilder: (context, index) {
//         if (index == users.length) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         final user = users[index];
//         return _buildUserCard(context, user['id'], user);
//       },
//     );
//   }

//   Widget _buildUserCard(
//     BuildContext context,
//     String userId,
//     Map<String, dynamic> userData,
//   ) {
//     final isActive = userData['isActive'] ?? true;
//     final name = userData['name'] ?? 'No Name';
//     final email = userData['email'] ?? 'No Email';
//     final phone = userData['phone'] ?? 'No Phone';
//     final imageUrl = userData['imageUrl'];
//     final age = userData['age']?.toString() ?? 'N/A';

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       color: Colors.white,
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) =>
//                 IndividualUserDetails(userId: userId, userData: userData),
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 width: 60,
//                 height: 60,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30),
//                   color: Colors.grey[200],

//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.2),
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: imageUrl != null
//                     ? ClipRRect(
//                         borderRadius: BorderRadius.circular(30),
//                         child: Image.network(
//                           imageUrl,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) => Icon(
//                             Icons.person,
//                             size: 30,
//                             color: Colors.grey[400],
//                           ),
//                         ),
//                       )
//                     : Icon(Icons.person, size: 30, color: Colors.grey[400]),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             name,
//                             style: const TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 5,
//                           ),
//                           decoration: BoxDecoration(
//                             color: isActive
//                                 ? Colors.green[100]
//                                 : Colors.red[100],
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             isActive ? 'Active' : 'Inactive',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: isActive
//                                   ? Colors.green[800]
//                                   : Colors.red[800],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       email,
//                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         Icon(Icons.phone, size: 16, color: Colors.grey[500]),
//                         const SizedBox(width: 6),
//                         Text(
//                           phone,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Icon(Icons.cake, size: 16, color: Colors.grey[500]),
//                         const SizedBox(width: 6),
//                         Text(
//                           '$age years',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:admin/Screens/Sales/salescontroller.dart';
import 'package:admin/Screens/Sales/individual_user_details.dart';
import 'package:admin/Screens/Users/addusers.dart';

class SalesManagementPage extends StatelessWidget {
  final SalesManagementController controller;

  const SalesManagementPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Sales Team',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: controller.resetAndFetchUsers,
            color: const Color(0xFF666666),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(controller),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: controller.users,
              builder: (context, users, _) {
                final filteredUsers = _getFilteredUsers(users);

                if (filteredUsers.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildUserList(context, filteredUsers);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddUserPage()),
        ),
        backgroundColor: const Color(0xFFD13443),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchSection(SalesManagementController controller) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search team members...',
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF666666),
                  size: 20,
                ),
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: controller.searchQuery,
                  builder: (context, query, _) => query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF666666),
                            size: 18,
                          ),
                          onPressed: () => controller.searchController.clear(),
                        )
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: controller.selectedFilter,
            builder: (context, filter, _) => Row(
              children: [
                _buildFilterChip(controller, 'All', 'all', filter),
                const SizedBox(width: 8),
                _buildFilterChip(controller, 'Active', 'active', filter),
                const SizedBox(width: 8),
                _buildFilterChip(controller, 'Inactive', 'inactive', filter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    SalesManagementController controller,
    String label,
    String value,
    String currentFilter,
  ) {
    final isSelected = currentFilter == value;
    return GestureDetector(
      onTap: () => controller.updateFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD13443) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD13443)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF666666),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Color(0xFFCCCCCC),
          ),
          SizedBox(height: 16),
          Text(
            'No team members found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<Map<String, dynamic>> users,
  ) {
    return ListView.builder(
      controller: controller.scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: users.length + (controller.isLoadingMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == users.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _buildUserCard(context, users[index]);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final isActive = user['isActive'] ?? true;
    final name = user['name'] ?? 'No Name';
    final email = user['email'] ?? 'No Email';
    final phone = user['phone'] ?? 'No Phone';
    final imageUrl = user['imageUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  IndividualUserDetails(userId: user['id'], userData: user),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFFF5F5F5),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person_rounded,
                                  size: 24,
                                  color: Color(0xFF999999),
                                ),
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 24,
                          color: Color(0xFF999999),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFCCCCCC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredUsers(
    List<Map<String, dynamic>> users,
  ) {
    return users.where((user) {
      final matchesFilter =
          controller.selectedFilter.value == 'all' ||
          (controller.selectedFilter.value == 'active' &&
              (user['isActive'] ?? true)) ||
          (controller.selectedFilter.value == 'inactive' &&
              !(user['isActive'] ?? true));

      final matchesSearch =
          controller.searchQuery.value.isEmpty ||
          (user['name']?.toLowerCase() ?? '').contains(
            controller.searchQuery.value.toLowerCase(),
          );

      return matchesFilter && matchesSearch;
    }).toList();
  }
}
