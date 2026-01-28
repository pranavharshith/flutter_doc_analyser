// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'admin_notifications_screen.dart';
// import 'admin_trash_screen.dart';
// import 'submission_popup.dart';
// import '/screens/auth/auth_page.dart';

// class Submission {
//   final String id;
//   final String name;
//   final String documentType;
//   String status;
//   final Timestamp submittedAt;
//   final Map<String, dynamic> details;
//   final double similarity;
//   final Map<String, String> verifiedFields;

//   Submission({
//     required this.id,
//     required this.name,
//     required this.documentType,
//     required this.status,
//     required this.submittedAt,
//     required this.details,
//     required this.similarity,
//     required this.verifiedFields,
//   });

//   factory Submission.fromMap(Map<String, dynamic> map, String id) {
//     return Submission(
//       id: id,
//       name: map['name'] ?? 'Unknown',
//       documentType: map['documentType'] ?? '',
//       status: map['status'] ?? 'Not Submitted',
//       submittedAt: map['submittedAt'] ?? Timestamp.now(),
//       details: map,
//       similarity: (map['overallSimilarity'] ?? 0.0).toDouble(),
//       verifiedFields: Map<String, String>.from(map['verifiedFields'] ?? {}),
//     );
//   }

//   // Helper method to check if submission is valid
//   bool isValid() {
//     return name.isNotEmpty &&
//         name != 'Unknown' &&
//         documentType.isNotEmpty &&
//         status.isNotEmpty;
//   }
// }

// class AdminDashboardScreen extends StatefulWidget {
//   const AdminDashboardScreen({super.key});

//   @override
//   _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
// }

// class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
//   String _searchQuery = '';
//   String _statusFilter = 'All';
//   Submission? _selectedSubmission;
//   bool _isLoading = true;
//   bool _isRefreshing = false;
//   Map<String, List<Submission>> _cachedSubmissions = {};

//   final List<String> _documentTypes = [
//     'Aadhar Card',
//     'Voter ID',
//     '10th Marksheet',
//     '12th Marksheet',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(const Duration(seconds: 1), () {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     });
//   }

//   void _updateStatus(Submission submission, String newStatus) async {
//     setState(() {
//       submission.status = newStatus;
//       _selectedSubmission = null;
//       final userName = submission.name;
//       final userSubmissions = _cachedSubmissions[userName] ?? [];
//       final index = userSubmissions.indexWhere((s) => s.id == submission.id);
//       if (index != -1) {
//         userSubmissions[index] = submission;
//         _cachedSubmissions[userName] = userSubmissions;
//       }
//     });

//     try {
//       final userId = submission.id.split('_')[0];
//       final docType = submission.documentType.toLowerCase().replaceAll(
//         ' ',
//         '_',
//       );
//       final docId = submission.id.split('_')[1];

//       await FirebaseFirestore.instance
//           .collection('students')
//           .doc(userId)
//           .collection('documents')
//           .doc(docType)
//           .collection('uploads')
//           .doc(docId)
//           .update({'status': newStatus});

//       if (newStatus == 'Rejected') {
//         await FirebaseFirestore.instance
//             .collection('students')
//             .doc(userId)
//             .collection('documents')
//             .doc(docType)
//             .update({'locked': false});

//         await FirebaseFirestore.instance
//             .collection('notifications')
//             .doc(userId)
//             .collection('userNotifications')
//             .add({
//               'message':
//                   'Your ${submission.documentType} was rejected. Please reupload.',
//               'documentType': submission.documentType,
//               'userId': userId,
//               'userName': submission.name,
//               'timestamp': FieldValue.serverTimestamp(),
//               'type': 'reupload',
//               'isRead': false,
//             });
//       } else if (newStatus == 'Verified') {
//         await FirebaseFirestore.instance
//             .collection('students')
//             .doc(userId)
//             .collection('documents')
//             .doc(docType)
//             .update({'locked': true});
//       }

//       await FirebaseFirestore.instance
//           .collection('notifications')
//           .doc(userId)
//           .collection('userNotifications')
//           .add({
//             'message': 'Your ${submission.documentType} has been $newStatus.',
//             'documentType': submission.documentType,
//             'userId': userId,
//             'userName': submission.name,
//             'timestamp': FieldValue.serverTimestamp(),
//             'type': 'user',
//             'isRead': false,
//           });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
//       }
//     }
//   }

//   Stream<Map<String, List<Submission>>> _getFilteredGroupedSubmissions() {
//     return FirebaseFirestore.instance
//         .collection('students')
//         .snapshots()
//         .asyncMap((snapshot) async {
//           final Map<String, List<Submission>> grouped = {};
//           final List<Future<void>> fetchFutures = [];

//           for (var userDoc in snapshot.docs) {
//             final userId = userDoc.id;
//             final userData = userDoc.data();
//             final role = userData['role'] ?? 'student';
//             if (role == 'admin') continue;

//             final userName = userData['name'] ?? 'Unknown';
//             final submissions = <Submission>[];

//             fetchFutures.add(
//               Future(() async {
//                 for (var docType in _documentTypes) {
//                   final docRef = FirebaseFirestore.instance
//                       .collection('students')
//                       .doc(userId)
//                       .collection('documents')
//                       .doc(docType.toLowerCase().replaceAll(' ', '_'))
//                       .collection('uploads')
//                       .orderBy('submittedAt', descending: true)
//                       .limit(1);

//                   final docSnapshot = await docRef.get();
//                   if (docSnapshot.docs.isNotEmpty) {
//                     final docData = docSnapshot.docs.first.data();
//                     final docId = docSnapshot.docs.first.id;
//                     submissions.add(
//                       Submission.fromMap({
//                         ...docData,
//                         'name': userName,
//                         'documentType': docType,
//                       }, '${userId}_$docId'),
//                     );
//                   } else {
//                     submissions.add(
//                       Submission(
//                         id: '${userId}_temp_$docType',
//                         name: userName,
//                         documentType: docType,
//                         status: 'Not Submitted',
//                         submittedAt: Timestamp.now(),
//                         details: {},
//                         similarity: 0.0,
//                         verifiedFields: {},
//                       ),
//                     );
//                   }
//                 }
//                 grouped[userName] = submissions;
//               }),
//             );
//           }

//           await Future.wait(fetchFutures);
//           _cachedSubmissions = grouped;
//           return grouped;
//         });
//   }

//   Future<void> _refreshData() async {
//     setState(() {
//       _isRefreshing = true;
//     });

//     try {
//       final grouped = await _getFilteredGroupedSubmissions().first;
//       if (mounted) {
//         setState(() {
//           _cachedSubmissions = grouped;
//           _isRefreshing = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isRefreshing = false;
//         });
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error refreshing data: $e')));
//       }
//     }
//   }

//   Stream<int> _getUnreadNotificationsCount() {
//     return FirebaseFirestore.instance
//         .collection('notifications')
//         .doc('admin')
//         .collection('adminNotifications')
//         .where('isRead', isEqualTo: false)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length);
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
//           ),
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: [
//               Column(
//                 children: [
//                   _buildAppBar(),
//                   _buildMenuBar(),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Padding(
//                         padding: const EdgeInsets.all(24.0),
//                         child: StreamBuilder<Map<String, List<Submission>>>(
//                           stream: _getFilteredGroupedSubmissions(),
//                           builder: (context, snapshot) {
//                             final groupedList =
//                                 snapshot.hasData
//                                     ? snapshot.data!
//                                     : _cachedSubmissions.isNotEmpty
//                                     ? _cachedSubmissions
//                                     : null;

//                             if (snapshot.connectionState ==
//                                     ConnectionState.waiting &&
//                                 groupedList == null) {
//                               return const Center(
//                                 child: CircularProgressIndicator(),
//                               );
//                             }

//                             if (snapshot.hasError) {
//                               return Center(
//                                 child: Text('Error: ${snapshot.error}'),
//                               );
//                             }

//                             if (groupedList == null || groupedList.isEmpty) {
//                               return const Center(
//                                 child: Text(
//                                   'No submissions found.',
//                                   style: TextStyle(color: Color(0xFF6B7280)),
//                                 ),
//                               );
//                             }

//                             final total = groupedList.values.fold(
//                               0,
//                               (sum, list) => sum + list.length,
//                             );
//                             final pending = groupedList.values.fold(
//                               0,
//                               (sum, list) =>
//                                   sum +
//                                   list
//                                       .where((s) => s.status == 'Pending')
//                                       .length,
//                             );
//                             final verified = groupedList.values.fold(
//                               0,
//                               (sum, list) =>
//                                   sum +
//                                   list
//                                       .where((s) => s.status == 'Verified')
//                                       .length,
//                             );
//                             final rejected = groupedList.values.fold(
//                               0,
//                               (sum, list) =>
//                                   sum +
//                                   list
//                                       .where((s) => s.status == 'Rejected')
//                                       .length,
//                             );

//                             return Column(
//                               children: [
//                                 _buildStats(total, pending, verified, rejected),
//                                 const SizedBox(height: 16),
//                                 _buildSearchBar(),
//                                 const SizedBox(height: 16),
//                                 FutureBuilder<Widget>(
//                                   future: _buildSubmissionList(groupedList),
//                                   builder: (context, snapshot) {
//                                     if (snapshot.connectionState ==
//                                         ConnectionState.waiting) {
//                                       return const Center(
//                                         child: CircularProgressIndicator(),
//                                       );
//                                     }
//                                     if (snapshot.hasError) {
//                                       return Center(
//                                         child: Text('Error: ${snapshot.error}'),
//                                       );
//                                     }
//                                     return snapshot.data ??
//                                         const SizedBox.shrink();
//                                   },
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               if (_selectedSubmission != null)
//                 SubmissionPopup(
//                   submission: _selectedSubmission!,
//                   onClose: () {
//                     setState(() {
//                       _selectedSubmission = null;
//                     });
//                   },
//                   onUpdateStatus: _updateStatus,
//                 ),
//               if (_isLoading)
//                 Container(
//                   color: Colors.black54,
//                   child: const Center(
//                     child: CircularProgressIndicator(color: Color(0xFF415A77)),
//                   ),
//                 ),
//               if (_isRefreshing)
//                 Positioned(
//                   top: 16,
//                   right: 16,
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.black54,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(
//                         color: Color(0xFF415A77),
//                         strokeWidth: 2,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF415A77), Color(0xFF1B263B)],
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               'ADMIN DASHBOARD',
//               style: TextStyle(
//                 color: const Color(0xFFFFFFFF),
//                 fontWeight: FontWeight.bold,
//                 fontSize: MediaQuery.of(context).size.width < 350 ? 16 : 18,
//                 letterSpacing: 1.2,
//               ),
//             ),
//           ),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.refresh, color: Color(0xFFFFFFFF)),
//                 iconSize: 20,
//                 padding: const EdgeInsets.all(8),
//                 constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//                 onPressed: _isRefreshing ? null : _refreshData,
//               ),
//               StreamBuilder<int>(
//                 stream: _getUnreadNotificationsCount(),
//                 builder: (context, snapshot) {
//                   final unreadCount = snapshot.data ?? 0;
//                   return Stack(
//                     children: [
//                       IconButton(
//                         icon: const Icon(
//                           Icons.notifications,
//                           color: Color(0xFFFFFFFF),
//                         ),
//                         iconSize: 20,
//                         padding: const EdgeInsets.all(8),
//                         constraints: const BoxConstraints(
//                           minWidth: 32,
//                           minHeight: 32,
//                         ),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (context) => const AdminNotificationsScreen(
//                                     isDarkMode: false,
//                                   ),
//                             ),
//                           );
//                         },
//                       ),
//                       if (unreadCount > 0)
//                         Positioned(
//                           right: 6,
//                           top: 6,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: const BoxDecoration(
//                               color: Colors.red,
//                               shape: BoxShape.circle,
//                             ),
//                             child: Text(
//                               unreadCount > 10 ? '10+' : unreadCount.toString(),
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   );
//                 },
//               ),
//               PopupMenuButton<String>(
//                 icon: const Icon(Icons.menu, color: Color(0xFFFFFFFF)),
//                 iconSize: 20,
//                 padding: const EdgeInsets.all(8),
//                 constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//                 onSelected: (value) async {
//                   if (value == 'Sign Out') {
//                     try {
//                       await FirebaseAuth.instance.signOut();
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (context) => AuthPage(
//                                 toggleDarkMode: () {},
//                                 isDarkMode: false,
//                               ),
//                         ),
//                       );
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Error signing out: $e')),
//                       );
//                     }
//                   } else if (value == 'Trash') {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const AdminTrashScreen(),
//                       ),
//                     );
//                   }
//                 },
//                 itemBuilder:
//                     (BuildContext context) => <PopupMenuEntry<String>>[
//                       const PopupMenuItem<String>(
//                         value: 'Trash',
//                         child: Text(
//                           'Trash',
//                           style: TextStyle(color: Colors.black),
//                         ),
//                       ),
//                       const PopupMenuItem<String>(
//                         value: 'Sign Out',
//                         child: Text(
//                           'Sign Out',
//                           style: TextStyle(color: Colors.red),
//                         ),
//                       ),
//                     ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             _buildMenuItem('All', _statusFilter == 'All', () {
//               setState(() {
//                 _statusFilter = 'All';
//               });
//             }),
//             _buildMenuItem('Pending', _statusFilter == 'Pending', () {
//               setState(() {
//                 _statusFilter = 'Pending';
//               });
//             }),
//             _buildMenuItem('Verified', _statusFilter == 'Verified', () {
//               setState(() {
//                 _statusFilter = 'Verified';
//               });
//             }),
//             _buildMenuItem('Rejected', _statusFilter == 'Rejected', () {
//               setState(() {
//                 _statusFilter = 'Rejected';
//               });
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuItem(String title, bool isSelected, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         margin: const EdgeInsets.only(right: 8),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isSelected ? const Color(0xFF415A77) : Colors.transparent,
//               width: 2,
//             ),
//           ),
//         ),
//         child: Text(
//           title,
//           style: TextStyle(
//             color:
//                 isSelected ? const Color(0xFF1B263B) : const Color(0xFF6B7280),
//             fontSize: 16,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStats(int total, int pending, int verified, int rejected) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F7FA),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildStatCard('Total', total, const Color(0xFF415A77)),
//           _buildStatCard('Pending', pending, const Color(0xFFF59E0B)),
//           _buildStatCard('Verified', verified, const Color(0xFF10B981)),
//           _buildStatCard('Rejected', rejected, const Color(0xFFEF4444)),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String label, int count, Color color) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: const Color(0xFF1B263B),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           count.toString(),
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchBar() {
//     return TextField(
//       decoration: const InputDecoration(
//         hintText: 'Search by name or document',
//         hintStyle: TextStyle(color: Color(0xFF6B7280)),
//         prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
//         filled: true,
//         fillColor: Color(0xFFF5F7FA),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.all(Radius.circular(12)),
//           borderSide: BorderSide.none,
//         ),
//         contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       ),
//       style: const TextStyle(color: Color(0xFF1B263B)),
//       onChanged: (value) {
//         setState(() {
//           _searchQuery = value;
//         });
//       },
//     );
//   }

//   Future<Widget> _buildSubmissionList(
//     Map<String, List<Submission>> groupedList,
//   ) async {
//     final filteredList =
//         groupedList.entries.where((entry) {
//           final name = entry.key.toLowerCase();
//           final submissions = entry.value;
//           if (_searchQuery.isEmpty) return true;
//           final query = _searchQuery.toLowerCase();
//           return name.contains(query) ||
//               submissions.any(
//                 (s) => s.documentType.toLowerCase().contains(query),
//               );
//         }).toList();

//     if (filteredList.isEmpty) {
//       return const Center(
//         child: Text(
//           'No submissions found.',
//           style: TextStyle(color: Color(0xFF6B7280)),
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: filteredList.length,
//       itemBuilder: (context, index) {
//         final name = filteredList[index].key;
//         final submissions =
//             filteredList[index].value
//                 .where(
//                   (s) => _statusFilter == 'All' || s.status == _statusFilter,
//                 )
//                 .toList();
//         if (submissions.isEmpty) return const SizedBox.shrink();

//         final uploadedCount =
//             submissions.where((s) => s.status != 'Not Submitted').length;
//         final totalDocs = _documentTypes.length;

//         return Container(
//           margin: const EdgeInsets.only(bottom: 16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: const Color(0xFF415A77).withOpacity(0.3),
//                       child: const Icon(Icons.person, color: Color(0xFFFFFFFF)),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             name,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF1B263B),
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '$uploadedCount/$totalDocs documents uploaded',
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Color(0xFF6B7280),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF5F7FA),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children:
//                       _documentTypes.map((docType) {
//                         final submission = submissions.firstWhere(
//                           (s) => s.documentType == docType,
//                           orElse:
//                               () => Submission(
//                                 id: 'temp_${name}_$docType',
//                                 name: name,
//                                 documentType: docType,
//                                 status: 'Not Submitted',
//                                 submittedAt: Timestamp.now(),
//                                 details: {},
//                                 similarity: 0.0,
//                                 verifiedFields: {},
//                               ),
//                         );

//                         return _buildDocumentCard(submission);
//                       }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDocumentCard(Submission submission) {
//     final Color statusColor = _getStatusColor(submission.status);
//     String? detailText;
//     List<Widget>? verificationDetails;
//     bool isHovered = false;

//     if (submission.documentType == 'Aadhar Card' &&
//         submission.status != 'Not Submitted') {
//       final details = submission.details['verificationDetails'];
//       if (details != null) {
//         final aadharNumber = details['aadharNumber']?['matchedText'] ?? '';
//         final name = details['name']?['matched'] ?? false;
//         final dob = details['dob']?['matched'] ?? false;
//         final aadharMatched = details['aadharNumber']?['matched'] ?? false;

//         detailText =
//             aadharNumber.isNotEmpty
//                 ? '**** **** ${aadharNumber.replaceAll(' ', '').substring(8)}'
//                 : null;

//         verificationDetails = [
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 name ? Icons.check_circle : Icons.error,
//                 color: name ? Colors.green : Colors.red,
//                 size: 8,
//               ),
//               const SizedBox(width: 2),
//               Text(
//                 'Name',
//                 style: TextStyle(
//                   fontSize: 8,
//                   color: name ? Colors.green : Colors.red,
//                 ),
//               ),
//             ],
//           ),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 dob ? Icons.check_circle : Icons.error,
//                 color: dob ? Colors.green : Colors.red,
//                 size: 8,
//               ),
//               const SizedBox(width: 2),
//               Text(
//                 'DOB',
//                 style: TextStyle(
//                   fontSize: 8,
//                   color: dob ? Colors.green : Colors.red,
//                 ),
//               ),
//             ],
//           ),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 aadharMatched ? Icons.check_circle : Icons.error,
//                 color: aadharMatched ? Colors.green : Colors.red,
//                 size: 8,
//               ),
//               const SizedBox(width: 2),
//               Text(
//                 'No.',
//                 style: TextStyle(
//                   fontSize: 8,
//                   color: aadharMatched ? Colors.green : Colors.red,
//                 ),
//               ),
//             ],
//           ),
//         ];
//       }
//     } else if (submission.documentType == 'Voter ID') {
//       detailText =
//           submission.status != 'Not Submitted' &&
//                   submission.verifiedFields['voterId'] != null
//               ? '**** **** ${submission.verifiedFields['voterId']!.substring(submission.verifiedFields['voterId']!.length - 4)}'
//               : null;
//     } else if (submission.documentType == '10th Marksheet' ||
//         submission.documentType == '12th Marksheet') {
//       detailText =
//           submission.status != 'Not Submitted' &&
//                   submission.verifiedFields['percentage'] != null
//               ? '${submission.verifiedFields['percentage']}%'
//               : null;
//     }

//     return StatefulBuilder(
//       builder: (context, setState) {
//         return MouseRegion(
//           onEnter: (_) => setState(() => isHovered = true),
//           onExit: (_) => setState(() => isHovered = false),
//           child: GestureDetector(
//             onTap: () {
//               this.setState(() {
//                 _selectedSubmission = submission;
//               });
//             },
//             child: Stack(
//               children: [
//                 Container(
//                   width: 80,
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: statusColor.withOpacity(0.3),
//                       width: 2,
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         _getDocumentIcon(submission.documentType),
//                         color:
//                             submission.status == 'Not Submitted'
//                                 ? const Color(0xFF6B7280).withOpacity(0.5)
//                                 : statusColor,
//                         size: 24,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         submission.documentType.split(' ')[0],
//                         style: TextStyle(
//                           fontSize: 12,
//                           color:
//                               submission.status == 'Not Submitted'
//                                   ? const Color(0xFF6B7280)
//                                   : const Color(0xFF1B263B),
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       if (submission.status != 'Not Submitted') ...[
//                         const SizedBox(height: 4),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 4,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: statusColor.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             '${submission.similarity.toStringAsFixed(0)}%',
//                             style: TextStyle(
//                               color: statusColor,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                       if (detailText != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           detailText,
//                           style: const TextStyle(
//                             fontSize: 10,
//                             color: Color(0xFF6B7280),
//                           ),
//                           textAlign: TextAlign.center,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                       if (verificationDetails != null) ...[
//                         const SizedBox(height: 4),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: verificationDetails,
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//                 if (isHovered && submission.status == 'Pending')
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.7),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           IconButton(
//                             icon: const Icon(
//                               Icons.check_circle,
//                               color: Colors.green,
//                             ),
//                             iconSize: 20,
//                             onPressed: () {
//                               _updateStatus(submission, 'Verified');
//                             },
//                           ),
//                           const SizedBox(height: 4),
//                           IconButton(
//                             icon: const Icon(Icons.cancel, color: Colors.red),
//                             iconSize: 20,
//                             onPressed: () {
//                               _updateStatus(submission, 'Rejected');
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   IconData _getDocumentIcon(String documentType) {
//     switch (documentType.toLowerCase()) {
//       case 'aadhar card':
//         return Icons.credit_card;
//       case 'voter id':
//         return Icons.how_to_vote;
//       case '10th marksheet':
//       case '12th marksheet':
//         return Icons.school;
//       default:
//         return Icons.description;
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'Verified':
//         return Colors.green;
//       case 'Rejected':
//         return Colors.red;
//       case 'Pending':
//         return Colors.orange;
//       default:
//         return const Color(0xFF6B7280);
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_notifications_screen.dart';
import 'admin_trash_screen.dart';
import 'submission_popup.dart';
import '/screens/auth/auth_page.dart';

class Submission {
  final String id;
  final String name;
  final String documentType;
  String status;
  final Timestamp submittedAt;
  final Map<String, dynamic> details;
  final double similarity;
  final Map<String, String> verifiedFields;

  Submission({
    required this.id,
    required this.name,
    required this.documentType,
    required this.status,
    required this.submittedAt,
    required this.details,
    required this.similarity,
    required this.verifiedFields,
  });

  factory Submission.fromMap(Map<String, dynamic> map, String id) {
    return Submission(
      id: id,
      name: map['name'] ?? 'Unknown',
      documentType: map['documentType'] ?? '',
      status: map['status'] ?? 'Not Submitted',
      submittedAt: map['submittedAt'] ?? Timestamp.now(),
      details: map,
      similarity: (map['overallSimilarity'] ?? 0.0).toDouble(),
      verifiedFields: Map<String, String>.from(map['verifiedFields'] ?? {}),
    );
  }

  bool isValid() {
    return name.isNotEmpty &&
        name != 'Unknown' &&
        documentType.isNotEmpty &&
        status.isNotEmpty;
  }
}

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const AdminDashboardScreen({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  Submission? _selectedSubmission;
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, List<Submission>> _cachedSubmissions = {};

  final List<String> _documentTypes = [
    'Aadhar Card',
    'Voter ID',
    '10th Marksheet',
    '12th Marksheet',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _updateStatus(Submission submission, String newStatus) async {
    setState(() {
      submission.status = newStatus;
      _selectedSubmission = null;
      final userName = submission.name;
      final userSubmissions = _cachedSubmissions[userName] ?? [];
      final index = userSubmissions.indexWhere((s) => s.id == submission.id);
      if (index != -1) {
        userSubmissions[index] = submission;
        _cachedSubmissions[userName] = userSubmissions;
      }
    });

    try {
      final userId = submission.id.split('_')[0];
      final docType = submission.documentType.toLowerCase().replaceAll(
        ' ',
        '_',
      );
      final docId = submission.id.split('_')[1];

      await FirebaseFirestore.instance
          .collection('students')
          .doc(userId)
          .collection('documents')
          .doc(docType)
          .collection('uploads')
          .doc(docId)
          .update({'status': newStatus});

      if (newStatus == 'Rejected') {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(userId)
            .collection('documents')
            .doc(docType)
            .update({'locked': false});

        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(userId)
            .collection('userNotifications')
            .add({
              'message':
                  'Your ${submission.documentType} was rejected. Please reupload.',
              'documentType': submission.documentType,
              'userId': userId,
              'userName': submission.name,
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'reupload',
              'isRead': false,
            });
      } else if (newStatus == 'Verified') {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(userId)
            .collection('documents')
            .doc(docType)
            .update({'locked': true});
      }

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('userNotifications')
          .add({
            'message': 'Your ${submission.documentType} has been $newStatus.',
            'documentType': submission.documentType,
            'userId': userId,
            'userName': submission.name,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'user',
            'isRead': false,
          });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  Stream<Map<String, List<Submission>>> _getFilteredGroupedSubmissions() {
    return FirebaseFirestore.instance
        .collection('students')
        .snapshots()
        .asyncMap((snapshot) async {
          final Map<String, List<Submission>> grouped = {};
          final List<Future<void>> fetchFutures = [];

          for (var userDoc in snapshot.docs) {
            final userId = userDoc.id;
            final userData = userDoc.data();
            final role = userData['role'] ?? 'student';
            if (role == 'admin') continue;

            final userName = userData['name'] ?? 'Unknown';
            final submissions = <Submission>[];

            fetchFutures.add(
              Future(() async {
                for (var docType in _documentTypes) {
                  final docRef = FirebaseFirestore.instance
                      .collection('students')
                      .doc(userId)
                      .collection('documents')
                      .doc(docType.toLowerCase().replaceAll(' ', '_'))
                      .collection('uploads')
                      .orderBy('submittedAt', descending: true)
                      .limit(1);

                  final docSnapshot = await docRef.get();
                  if (docSnapshot.docs.isNotEmpty) {
                    final docData = docSnapshot.docs.first.data();
                    final docId = docSnapshot.docs.first.id;
                    submissions.add(
                      Submission.fromMap({
                        ...docData,
                        'name': userName,
                        'documentType': docType,
                      }, '${userId}_$docId'),
                    );
                  } else {
                    submissions.add(
                      Submission(
                        id: '${userId}_temp_$docType',
                        name: userName,
                        documentType: docType,
                        status: 'Not Submitted',
                        submittedAt: Timestamp.now(),
                        details: {},
                        similarity: 0.0,
                        verifiedFields: {},
                      ),
                    );
                  }
                }
                grouped[userName] = submissions;
              }),
            );
          }

          await Future.wait(fetchFutures);
          _cachedSubmissions = grouped;
          return grouped;
        });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final grouped = await _getFilteredGroupedSubmissions().first;
      if (mounted) {
        setState(() {
          _cachedSubmissions = grouped;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error refreshing data: $e')));
      }
    }
  }

  Stream<int> _getUnreadNotificationsCount() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc('admin')
        .collection('adminNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isDarkMode
                ? [const Color(0xFF1B263B), const Color(0xFF0A111F)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  _buildMenuBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: StreamBuilder<Map<String, List<Submission>>>(
                          stream: _getFilteredGroupedSubmissions(),
                          builder: (context, snapshot) {
                            final groupedList =
                                snapshot.hasData
                                    ? snapshot.data!
                                    : _cachedSubmissions.isNotEmpty
                                    ? _cachedSubmissions
                                    : null;

                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                groupedList == null) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? const Color(0xFFB0C4DE)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              );
                            }

                            if (groupedList == null || groupedList.isEmpty) {
                              return Center(
                                child: Text(
                                  'No submissions found.',
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? const Color(0xFFB0C4DE)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              );
                            }

                            final total = groupedList.values.fold(
                              0,
                              (sum, list) => sum + list.length,
                            );
                            final pending = groupedList.values.fold(
                              0,
                              (sum, list) =>
                                  sum +
                                  list
                                      .where((s) => s.status == 'Pending')
                                      .length,
                            );
                            final verified = groupedList.values.fold(
                              0,
                              (sum, list) =>
                                  sum +
                                  list
                                      .where((s) => s.status == 'Verified')
                                      .length,
                            );
                            final rejected = groupedList.values.fold(
                              0,
                              (sum, list) =>
                                  sum +
                                  list
                                      .where((s) => s.status == 'Rejected')
                                      .length,
                            );

                            return Column(
                              children: [
                                _buildStats(total, pending, verified, rejected),
                                const SizedBox(height: 16),
                                _buildSearchBar(),
                                const SizedBox(height: 16),
                                FutureBuilder<Widget>(
                                  future: _buildSubmissionList(groupedList),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Text(
                                          'Error: ${snapshot.error}',
                                          style: TextStyle(
                                            color: widget.isDarkMode
                                                ? const Color(0xFFB0C4DE)
                                                : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      );
                                    }
                                    return snapshot.data ??
                                        const SizedBox.shrink();
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedSubmission != null)
                SubmissionPopup(
                  submission: _selectedSubmission!,
                  onClose: () {
                    setState(() {
                      _selectedSubmission = null;
                    });
                  },
                  onUpdateStatus: _updateStatus,
                ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF415A77)),
                  ),
                ),
              if (_isRefreshing)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Color(0xFF415A77),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF415A77), Color(0xFF1B263B)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'ADMIN DASHBOARD',
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width < 350 ? 16 : 18,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFFFFFFFF)),
                iconSize: 20,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _isRefreshing ? null : _refreshData,
              ),
              StreamBuilder<int>(
                stream: _getUnreadNotificationsCount(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Color(0xFFFFFFFF),
                        ),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AdminNotificationsScreen(
                                    isDarkMode: widget.isDarkMode,
                                  ),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 10 ? '10+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu, color: Color(0xFFFFFFFF)),
                iconSize: 20,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onSelected: (value) async {
                  if (value == 'Sign Out') {
                    try {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AuthPage(
                                toggleDarkMode: widget.toggleDarkMode,
                                isDarkMode: widget.isDarkMode,
                              ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  } else if (value == 'Trash') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminTrashScreen(),
                      ),
                    );
                  } else if (value == 'ToggleTheme') {
                    widget.toggleDarkMode();
                  }
                },
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'ToggleTheme',
                        child: Text(
                          widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? const Color(0xFFB0C4DE)
                                : const Color(0xFF1B263B),
                          ),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Trash',
                        child: Text(
                          'Trash',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Sign Out',
                        child: Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMenuItem('All', _statusFilter == 'All', () {
              setState(() {
                _statusFilter = 'All';
              });
            }),
            _buildMenuItem('Pending', _statusFilter == 'Pending', () {
              setState(() {
                _statusFilter = 'Pending';
              });
            }),
            _buildMenuItem('Verified', _statusFilter == 'Verified', () {
              setState(() {
                _statusFilter = 'Verified';
              });
            }),
            _buildMenuItem('Rejected', _statusFilter == 'Rejected', () {
              setState(() {
                _statusFilter = 'Rejected';
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF415A77) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF1B263B)
                : widget.isDarkMode
                    ? const Color(0xFFB0C4DE)
                    : const Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStats(int total, int pending, int verified, int rejected) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF2A3A5A)
            : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total', total, const Color(0xFF415A77)),
          _buildStatCard('Pending', pending, const Color(0xFFF59E0B)),
          _buildStatCard('Verified', verified, const Color(0xFF10B981)),
          _buildStatCard('Rejected', rejected, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF1B263B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by name or document',
        hintStyle: TextStyle(
          color: widget.isDarkMode
              ? const Color(0xFFB0C4DE)
              : const Color(0xFF6B7280),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: widget.isDarkMode
              ? const Color(0xFFB0C4DE)
              : const Color(0xFF6B7280),
        ),
        filled: true,
        fillColor: widget.isDarkMode
            ? const Color(0xFF3B4A6B)
            : const Color(0xFFF5F7FA),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      style: TextStyle(
        color: widget.isDarkMode
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF1B263B),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Future<Widget> _buildSubmissionList(
    Map<String, List<Submission>> groupedList,
  ) async {
    final filteredList =
        groupedList.entries.where((entry) {
          final name = entry.key.toLowerCase();
          final submissions = entry.value;
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return name.contains(query) ||
              submissions.any(
                (s) => s.documentType.toLowerCase().contains(query),
              );
        }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          'No submissions found.',
          style: TextStyle(
            color: widget.isDarkMode
                ? const Color(0xFFB0C4DE)
                : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final name = filteredList[index].key;
        final submissions =
            filteredList[index].value
                .where(
                  (s) => _statusFilter == 'All' || s.status == _statusFilter,
                )
                .toList();
        if (submissions.isEmpty) return const SizedBox.shrink();

        final uploadedCount =
            submissions.where((s) => s.status != 'Not Submitted').length;
        final totalDocs = _documentTypes.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? const Color(0xFF2A3A5A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF415A77).withOpacity(0.3),
                      child: const Icon(Icons.person, color: Color(0xFFFFFFFF)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF1B263B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$uploadedCount/$totalDocs documents uploaded',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isDarkMode
                                  ? const Color(0xFFB0C4DE)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(0xFF3B4A6B)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      _documentTypes.map((docType) {
                        final submission = submissions.firstWhere(
                          (s) => s.documentType == docType,
                          orElse:
                              () => Submission(
                                id: 'temp_${name}_$docType',
                                name: name,
                                documentType: docType,
                                status: 'Not Submitted',
                                submittedAt: Timestamp.now(),
                                details: {},
                                similarity: 0.0,
                                verifiedFields: {},
                              ),
                        );

                        return _buildDocumentCard(submission);
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(Submission submission) {
    final Color statusColor = _getStatusColor(submission.status);
    String? detailText;
    List<Widget>? verificationDetails;
    bool isHovered = false;

    if (submission.documentType == 'Aadhar Card' &&
        submission.status != 'Not Submitted') {
      final details = submission.details['verificationDetails'];
      if (details != null) {
        final aadharNumber = details['aadharNumber']?['matchedText'] ?? '';
        final name = details['name']?['matched'] ?? false;
        final dob = details['dob']?['matched'] ?? false;
        final aadharMatched = details['aadharNumber']?['matched'] ?? false;

        detailText =
            aadharNumber.isNotEmpty
                ? '**** **** ${aadharNumber.replaceAll(' ', '').substring(8)}'
                : null;

        verificationDetails = [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                name ? Icons.check_circle : Icons.error,
                color: name ? Colors.green : Colors.red,
                size: 6,
              ),
              const SizedBox(width: 2),
              Text(
                'Name',
                style: TextStyle(
                  fontSize: 6,
                  color: name ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                dob ? Icons.check_circle : Icons.error,
                color: dob ? Colors.green : Colors.red,
                size: 6,
              ),
              const SizedBox(width: 2),
              Text(
                'DOB',
                style: TextStyle(
                  fontSize: 6,
                  color: dob ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aadharMatched ? Icons.check_circle : Icons.error,
                color: aadharMatched ? Colors.green : Colors.red,
                size: 6,
              ),
              const SizedBox(width: 2),
              Text(
                'No.',
                style: TextStyle(
                  fontSize: 6,
                  color: aadharMatched ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ];
      }
    } else if (submission.documentType == 'Voter ID') {
      detailText =
          submission.status != 'Not Submitted' &&
                  submission.verifiedFields['voterId'] != null
              ? '**** **** ${submission.verifiedFields['voterId']!.substring(submission.verifiedFields['voterId']!.length - 4)}'
              : null;
    } else if (submission.documentType == '10th Marksheet' ||
        submission.documentType == '12th Marksheet') {
      detailText =
          submission.status != 'Not Submitted' &&
                  submission.verifiedFields['percentage'] != null
              ? '${submission.verifiedFields['percentage']}%'
              : null;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              this.setState(() {
                _selectedSubmission = submission;
              });
            },
            child: Stack(
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? const Color(0xFF2A3A5A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDocumentIcon(submission.documentType),
                        color:
                            submission.status == 'Not Submitted'
                                ? (widget.isDarkMode
                                        ? const Color(0xFFB0C4DE)
                                        : const Color(0xFF6B7280))
                                    .withOpacity(0.5)
                                : statusColor,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        submission.documentType.split(' ')[0],
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              submission.status == 'Not Submitted'
                                  ? (widget.isDarkMode
                                      ? const Color(0xFFB0C4DE)
                                      : const Color(0xFF6B7280))
                                  : (widget.isDarkMode
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFF1B263B)),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (submission.status != 'Not Submitted') ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${submission.similarity.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (detailText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          detailText,
                          style: TextStyle(
                            fontSize: 8,
                            color: widget.isDarkMode
                                ? const Color(0xFFB0C4DE)
                                : const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (verificationDetails != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: verificationDetails,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isHovered && submission.status == 'Pending')
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            iconSize: 20,
                            onPressed: () {
                              _updateStatus(submission, 'Verified');
                            },
                          ),
                          const SizedBox(height: 4),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            iconSize: 20,
                            onPressed: () {
                              _updateStatus(submission, 'Rejected');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'aadhar card':
        return Icons.credit_card;
      case 'voter id':
        return Icons.how_to_vote;
      case '10th marksheet':
      case '12th marksheet':
        return Icons.school;
      default:
        return Icons.description;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Verified':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return const Color(0xFF6B7280);
    }
  }
}