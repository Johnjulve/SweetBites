import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/update_service.dart';

/// Screen for managing bakery contact, receipt branding, and app updates.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _repoController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  // App Update State
  bool _isCheckingUpdate = false;
  AppReleaseInfo? _latestRelease;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _repoController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _nameController.text =
          prefs.getString(AppConstants.prefBakeryName) ??
          AppConstants.defaultBakeryName;
      _addressController.text =
          prefs.getString(AppConstants.prefBakeryAddress) ??
          AppConstants.defaultBakeryAddress;
      _phoneController.text =
          prefs.getString(AppConstants.prefBakeryPhone) ??
          AppConstants.defaultBakeryPhone;
      _repoController.text =
          prefs.getString(AppConstants.prefGithubRepo) ??
          AppConstants.defaultGithubRepo;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.prefBakeryName,
        _nameController.text.trim(),
      );
      await prefs.setString(
        AppConstants.prefBakeryAddress,
        _addressController.text.trim(),
      );
      await prefs.setString(
        AppConstants.prefBakeryPhone,
        _phoneController.text.trim(),
      );
      await prefs.setString(
        AppConstants.prefGithubRepo,
        _repoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Settings saved successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final repo = _repoController.text.trim().isNotEmpty
          ? _repoController.text.trim()
          : AppConstants.defaultGithubRepo;

      final release = await UpdateService.checkForUpdates(
        repo: repo,
        currentVersion: AppConstants.appVersion,
      );

      if (!mounted) return;
      setState(() {
        _latestRelease = release;
        _isCheckingUpdate = false;
      });

      if (release == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No GitHub releases found for this repository yet.'),
          ),
        );
      } else if (!release.hasUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('SweetBites is up to date (v${AppConstants.appVersion})!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingUpdate = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not check for updates: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showReleaseNotesModal(AppReleaseInfo release) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final modalTheme = Theme.of(ctx);
        final isDark = modalTheme.brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: modalTheme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerOf(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFE8734A).withValues(alpha: 0.2)
                          : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      release.tagName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      release.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: modalTheme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Text(
              "What's New:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  release.body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.done),
                label: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bakery & App Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Receipt Branding
                    Card(
                      elevation: 0,
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFFE8734A).withValues(alpha: 0.14)
                          : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFFE8734A).withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront,
                              color: theme.colorScheme.primary,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Receipt Branding',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.brightness == Brightness.dark
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Configure the details printed at the top of your customer receipts.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.brightness == Brightness.dark
                                          ? const Color(0xFFB5A496)
                                          : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bakery Name Field
                    Text(
                      'Bakery Name',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. SweetBites Pastry & Cafe',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your bakery name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bakery Phone Field
                    Text(
                      'Contact Number',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. +63 912 345 6789',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bakery Address Field
                    Text(
                      'Address / Branch',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      keyboardType: TextInputType.streetAddress,
                      decoration: InputDecoration(
                        hintText: 'e.g. 123 Baker Street, Sweet City',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section 2: App Version & GitHub Updates
                    const Divider(),
                    const SizedBox(height: 16),

                    Text(
                      'App Updates & GitHub',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connect with GitHub Releases to check for and receive app updates.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFFB5A496)
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Update Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF241F1B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF382F28)
                              : AppTheme.dividerColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark
                                      ? const Color(0xFFE8734A).withValues(alpha: 0.2)
                                      : AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.system_update_alt, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'SweetBites',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.brightness == Brightness.dark
                                                ? const Color(0xFF2E2722)
                                                : AppTheme.surfaceDim,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'v${AppConstants.appVersion}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: theme.brightness == Brightness.dark
                                                  ? const Color(0xFFB5A496)
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _latestRelease == null
                                          ? 'Ready to check for updates'
                                          : _latestRelease!.hasUpdate
                                              ? 'New update available: ${_latestRelease!.tagName}'
                                              : 'You are on the latest version',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _latestRelease?.hasUpdate == true
                                            ? AppTheme.primaryColor
                                            : (theme.brightness == Brightness.dark
                                                ? const Color(0xFFB5A496)
                                                : AppTheme.textSecondary),
                                        fontWeight: _latestRelease?.hasUpdate == true
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_latestRelease != null && _latestRelease!.hasUpdate) ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _showReleaseNotesModal(_latestRelease!),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'View ${_latestRelease!.tagName} release notes',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                              icon: _isCheckingUpdate
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh, size: 20),
                              label: Text(_isCheckingUpdate ? 'Checking GitHub...' : 'Check for Updates'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // GitHub Repository field
                    Text(
                      'GitHub Repository (owner/repo)',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _repoController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Johnjulve/SweetBites',
                        prefixIcon: const Icon(Icons.code),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Settings',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
