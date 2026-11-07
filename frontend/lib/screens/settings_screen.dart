import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../services/security_service.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import 'passcode_setup_screen.dart';
import 'passcode_options_screen.dart';
import 'passcode_lock_screen.dart';
import 'backup_screen.dart';
import 'feedback_screen.dart';
import 'settings/widgets/settings_tile.dart';
import 'settings/privacy_policy_screen.dart';
import 'settings/budgets_management_screen.dart';
import 'settings/general_settings_screen.dart';
import 'settings/faq_screen.dart';
import '../services/app_review_service.dart';

// Main settings hub (previously ProfileScreen in profile_screen.dart)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isPasscodeOn = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _checkPasscodeStatus();
    _checkNotificationStatus();
    _loadAppVersion();
  }

  Future<void> _checkNotificationStatus() async {
    final enabled = await NotificationService().areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  Future<void> _checkPasscodeStatus() async {
    final hasPasscode = await SecurityService().hasPasscode();
    if (mounted) {
      setState(() {
        _isPasscodeOn = hasPasscode;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Watch providers so the settings screen rebuilds when they change
    context.watch<SettingsProvider>();
    context.watch<ThemeProvider>();
    context.watch<LanguageProvider>();

    // Passcode Status
    final passcodeStatus = _isPasscodeOn ? 'On' : 'Off';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildSectionHeader(context, 'app_settings'),
              _buildSectionCard(context, [
                SettingsTile(
                  title: context.translate('general'),
                  icon: Icons.tune_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GeneralSettingsScreen(),
                    ),
                  ),
                ),
                SettingsTile(
                  title: context.translate('budgets'),
                  icon: Icons.track_changes_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BudgetsManagementScreen(),
                    ),
                  ),
                ),
                SettingsTile(
                  title: context.translate('notifications'),
                  icon: Icons.notifications_none,
                  onTap: () {},
                  trailing: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _notificationsEnabled,
                      onChanged: (val) async {
                        setState(() => _notificationsEnabled = val);
                        await NotificationService().setNotificationsEnabled(
                          val,
                        );
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              _buildSectionHeader(context, 'security_and_data'),
              _buildSectionCard(context, [
                SettingsTile(
                  title: context.translate('passcode'),
                  icon: Icons.lock_outline,
                  onTap: () => _navigateToPasscode(context),
                  status: passcodeStatus,
                ),
                SettingsTile(
                  title: context.translate('backup'),
                  icon: Icons.cloud_upload_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackupScreen(),
                      ),
                    );
                  },
                  status: 'Google Drive',
                ),
                SettingsTile(
                  title: context.translate('clear_data'),
                  icon: Icons.delete_outline_rounded,
                  iconColor: cs.error,
                  onTap: () => _showClearDataModal(context),
                ),
              ]),
              const SizedBox(height: 8),

              _buildSectionHeader(context, 'support_and_feedback'),
              _buildSectionCard(context, [
                SettingsTile(
                  title: context.translate('faq'),
                  icon: Icons.help_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaqScreen(),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  title: context.translate('feedback'),
                  icon: Icons.feedback_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeedbackScreen(),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  title: context.translate('rate_us'),
                  icon: Icons.star_outline,
                  onTap: () {
                    AppReviewService.requestInAppReviewDirectly();
                  },
                ),
              ]),
              const SizedBox(height: 8),

              _buildSectionHeader(context, 'about'),
              _buildSectionCard(context, [
                SettingsTile(
                  title: context.translate('privacy_policy'),
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
              
              // Version Info
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _appVersion.isNotEmpty
                      ? context.translate('version_info').replaceAll('1.0.0 (1)', _appVersion)
                      : context.translate('version_info'),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String titleKey) {
    String title = context.translate(titleKey);
    if (title.toUpperCase() == "SETTINGS") {
      title = "Settings";
    } else {
      title = _toTitleCase(title);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500, // Medium weight for header text
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45), // Sleek, modern grey
        ),
      ),
    );
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildSectionCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            indent: 60, // Perfectly aligns with the start of the title text
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: dividedChildren,
        ),
      ),
    );
  }

  void _navigateToPasscode(BuildContext context) async {
    final hasPasscode = await SecurityService().hasPasscode();
    if (!context.mounted) return;

    if (hasPasscode) {
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/lock_screen'),
          builder: (context) =>
              const PasscodeLockScreen(verificationOnly: true),
        ),
      );

      if (verified == true && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PasscodeOptionsScreen(),
          ),
        ).then((_) {
          _checkPasscodeStatus();
        });
      }
    } else {
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const PasscodeSetupScreen()),
      );

      if (success == true && mounted) {
        // Immediately redirect to passcode settings options screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PasscodeOptionsScreen(),
          ),
        ).then((_) {
          _checkPasscodeStatus();
        });
      }
    }
  }

  void _showClearDataModal(BuildContext context) {
    String selectedMode = 'tx_only'; // 'tx_only' or 'full'
    bool isClearing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final theme = Theme.of(modalContext);
            final cs = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: cs.error,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.translate('clear_app_data_title'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.translate('clear_app_data_subtitle'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Option 1: Clear Transactions Only
                    InkWell(
                      onTap: isClearing
                          ? null
                          : () {
                              setModalState(() {
                                selectedMode = 'tx_only';
                              });
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedMode == 'tx_only'
                              ? (isDark
                                  ? const Color(0xFF222428)
                                  : const Color(0xFFF1F3F5))
                              : (isDark
                                  ? const Color(0xFF181A1D)
                                  : const Color(0xFFF8F9FA)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedMode == 'tx_only'
                                ? cs.onSurface.withValues(alpha: 0.25)
                                : cs.onSurface.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedMode == 'tx_only'
                                        ? cs.primary
                                        : cs.onSurface.withValues(alpha: 0.3),
                                    width: selectedMode == 'tx_only' ? 2 : 1.5,
                                  ),
                                ),
                                child: selectedMode == 'tx_only'
                                    ? Center(
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: cs.primary,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.translate(
                                      'clear_transactions_only_title',
                                    ),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.translate(
                                      'clear_transactions_only_desc',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.4,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Option 2: Full Factory Reset
                    InkWell(
                      onTap: isClearing
                          ? null
                          : () {
                              setModalState(() {
                                selectedMode = 'full';
                              });
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedMode == 'full'
                              ? cs.error.withValues(alpha: 0.05)
                              : (isDark
                                  ? const Color(0xFF181A1D)
                                  : const Color(0xFFF8F9FA)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedMode == 'full'
                                ? cs.error.withValues(alpha: 0.35)
                                : cs.onSurface.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedMode == 'full'
                                        ? cs.error
                                        : cs.onSurface.withValues(alpha: 0.3),
                                    width: selectedMode == 'full' ? 2 : 1.5,
                                  ),
                                ),
                                child: selectedMode == 'full'
                                    ? Center(
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: cs.error,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.translate(
                                      'clear_factory_reset_title',
                                    ),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: cs.error,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.translate(
                                      'clear_factory_reset_desc',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.4,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
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

                    // Action Buttons
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isClearing
                                  ? null
                                  : () => Navigator.pop(bottomSheetContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: cs.onSurface.withValues(alpha: 0.12),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                context.translate('cancel'),
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isClearing
                                  ? null
                                  : () async {
                                      final confirmed = await showDialog<bool>(
                                        context: bottomSheetContext,
                                        builder: (alertDialogContext) {
                                          return AlertDialog(
                                            backgroundColor: cs.surface,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            title: Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: cs.error,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  context.translate(
                                                    'clear_confirm_title',
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: Text(
                                              selectedMode == 'tx_only'
                                                  ? context.translate(
                                                      'clear_confirm_tx_desc',
                                                    )
                                                  : context.translate(
                                                      'clear_confirm_full_desc',
                                                    ),
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                height: 1.45,
                                                color: cs.onSurface.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                            ),
                                            actionsPadding:
                                                const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              16,
                                            ),
                                            actions: [
                                              IntrinsicHeight(
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                          alertDialogContext,
                                                          false,
                                                        ),
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: 12,
                                                          ),
                                                          side: BorderSide(
                                                            color: cs.onSurface
                                                                .withValues(
                                                              alpha: 0.12,
                                                            ),
                                                          ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              10,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          context.translate(
                                                            'cancel',
                                                          ),
                                                          style: TextStyle(
                                                            color: cs.onSurface
                                                                .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 13.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                          alertDialogContext,
                                                          true,
                                                        ),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              cs.error,
                                                          elevation: 0,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            vertical: 12,
                                                          ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              10,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          context.translate(
                                                            'btn_yes_delete',
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 13.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirmed != true) return;
                                      if (!context.mounted) return;

                                      setModalState(() {
                                        isClearing = true;
                                      });

                                      try {
                                        final firestore = context
                                            .read<FirestoreService>();
                                        if (selectedMode == 'tx_only') {
                                          await firestore
                                              .clearTransactionsOnly();
                                        } else {
                                          await firestore.clearAllUserData();
                                        }

                                        if (context.mounted) {
                                          Navigator.pop(bottomSheetContext);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                selectedMode == 'tx_only'
                                                    ? context.translate(
                                                        'msg_tx_cleared',
                                                      )
                                                    : context.translate(
                                                        'msg_data_reset',
                                                      ),
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          setModalState(() {
                                            isClearing = false;
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${context.translate('msg_clear_failed')}: $e',
                                              ),
                                              backgroundColor: cs.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.error,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isClearing
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      context.translate('clear_data'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
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
          },
        );
      },
    );
  }
}
