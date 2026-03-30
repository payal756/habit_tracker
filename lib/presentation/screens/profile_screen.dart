import 'package:flutter/material.dart';
import 'package:mahadev/data/models/user_model.dart';
import 'package:mahadev/core/services/hive_service.dart';
import 'package:mahadev/core/services/api_service.dart';
import 'package:mahadev/presentation/screens/auth/change_password_screen.dart';
import 'package:mahadev/presentation/screens/auth/data_management_screen.dart';
import 'package:mahadev/presentation/screens/notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? userData;
  final Future<void> Function() onRefresh;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.userData,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  String? _selectedProfession;
  List<String> _selectedGoals = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.userData?.name ?? '');
    _emailController = TextEditingController(
      text: widget.userData?.email ?? '',
    );
    _ageController = TextEditingController(
      text: widget.userData?.age?.toString() ?? '',
    );
    _selectedProfession = widget.userData?.profession;
    _selectedGoals = List.from(widget.userData?.goals ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    try {
      await _apiService.put('/auth/profile', {
        'name': _nameController.text,
        'age': _ageController.text.isNotEmpty
            ? int.parse(_ageController.text)
            : null,
        'profession': _selectedProfession,
        'goals': _selectedGoals,
      });

      final updatedUser = UserModel(
        id: widget.userData!.id,
        name: _nameController.text,
        email: widget.userData!.email,
        age: _ageController.text.isNotEmpty
            ? int.parse(_ageController.text)
            : null,
        profession: _selectedProfession,
        goals: _selectedGoals,
        coins: widget.userData!.coins,
      );

      await HiveService.saveUser(updatedUser);
      await widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        // physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.05,
                MediaQuery.of(context).padding.top + 20,
                screenWidth * 0.05,
                30,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: screenWidth * 0.25,
                    height: screenWidth * 0.25,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.userData?.name?.substring(0, 1).toUpperCase() ??
                            'U',
                        style: TextStyle(
                          fontSize: screenWidth * 0.1,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.userData?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userData?.email ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatBadge(
                        icon: Icons.currency_bitcoin,
                        value: '${widget.userData?.coins ?? 0}',
                        label: 'Coins',
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 20),
                      _buildStatBadge(
                        icon: Icons.flag,
                        value: '21',
                        label: 'Days Goal',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 20),
                      _buildStatBadge(
                        icon: Icons.emoji_events,
                        value: '${_selectedGoals.length}',
                        label: 'Goals',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Profile Details
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Edit Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                          if (!_isEditing) {
                            _updateProfile();
                          }
                        });
                      },
                      icon: Icon(
                        _isEditing ? Icons.save : Icons.edit,
                        size: 20,
                        color: theme.primaryColor,
                      ),
                      label: Text(
                        _isEditing ? 'Save' : 'Edit Profile',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Personal Information
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.person,
                    label: 'Full Name',
                    value: _nameController.text,
                    isEditing: _isEditing,
                    onEdit: (value) {
                      _nameController.text = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.email,
                    label: 'Email Address',
                    value: _emailController.text,
                    isEditing: false,
                    editable: false,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.cake,
                    label: 'Age',
                    value: _ageController.text,
                    isEditing: _isEditing,
                    onEdit: (value) {
                      _ageController.text = value;
                    },
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownCard(
                    icon: Icons.work,
                    label: 'Profession',
                    value: _selectedProfession,
                    items: const [
                      'Student',
                      'Developer',
                      'Designer',
                      'Teacher',
                      'Healthcare',
                      'Business',
                      'Other',
                    ],
                    isEditing: _isEditing,
                    onChanged: (value) {
                      setState(() {
                        _selectedProfession = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Goals Section
                  Text(
                    'Your Goals',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isEditing
                        ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                const [
                                  'Exercise Daily',
                                  'Meditation',
                                  'Read Books',
                                  'Learn Coding',
                                  'Eat Healthy',
                                  'Sleep Better',
                                  'Drink Water',
                                  'Practice Gratitude',
                                  'Journaling',
                                  'Learn Language',
                                ].map((goal) {
                                  final isSelected = _selectedGoals.contains(
                                    goal,
                                  );
                                  return FilterChip(
                                    label: Text(goal),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedGoals.add(goal);
                                        } else {
                                          _selectedGoals.remove(goal);
                                        }
                                      });
                                    },
                                    selectedColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList(),
                          )
                        : _selectedGoals.isEmpty
                        ? const Text(
                            'No goals selected yet',
                            style: TextStyle(color: Colors.grey),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedGoals.map((goal) {
                              return Chip(
                                label: Text(goal),
                                backgroundColor: Colors.green.shade100,
                                labelStyle: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 24),
                  // Account Actions
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.lock_outline,
                            color: Colors.orange,
                          ),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.data_usage,
                            color: Colors.blue,
                          ),
                          title: const Text('Data Management'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DataManagementScreen(
                                  onDataCleared: widget.onRefresh,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.purple,
                          ),
                          title: const Text('Notifications'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Version Info
                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    bool editable = true,
    Function(String)? onEdit,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                isEditing && editable
                    ? TextFormField(
                        initialValue: value,
                        onChanged: onEdit,
                        keyboardType: keyboardType,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      )
                    : Text(
                        value.isEmpty ? 'Not set' : value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCard({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required bool isEditing,
    required Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                isEditing
                    ? DropdownButtonFormField<String>(
                        value: value,
                        items: items.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: onChanged,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      )
                    : Text(
                        value ?? 'Not set',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
