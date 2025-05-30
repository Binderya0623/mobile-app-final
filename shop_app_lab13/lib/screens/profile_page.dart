import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/global_provider.dart';
import '../provider/language_provider.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GlobalProvider, LanguageProvider>(
      builder: (context, provider, languageProvider, child) {
        if (!provider.isLoggedIn) return const LoginPage();

        // Firebase backed-ees user model avah
        final userModel = provider.currentUserModel!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              languageProvider.translate('profile'),
              style: const TextStyle(color: Colors.black87),
            ),
            iconTheme: const IconThemeData(color: Colors.black54),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // email
                        _buildRowItem(
                          icon: Icons.email,
                          label: languageProvider.translate('email'),
                          value: userModel.email,
                        ),
                        const SizedBox(height: 12),

                        // name
                        _buildRowItem(
                          icon: Icons.person,
                          label: languageProvider.translate('full_name'),
                          value: userModel.displayName,
                        ),
                        const SizedBox(height: 20),

                        // language
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.language, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                languageProvider.translate('language'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            DropdownButton<String>(
                              underline: const SizedBox(),
                              value: languageProvider.currentLanguageCode,
                              items: [
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text(languageProvider.translate('english')),
                                ),
                                DropdownMenuItem(
                                  value: 'mn',
                                  child: Text(languageProvider.translate('mongolian')),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) languageProvider.setLanguage(val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // logout
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: provider.logout,
                            icon: const Icon(Icons.logout),
                            label: Text(languageProvider.translate('logout')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              foregroundColor: Colors.red,
                            ),
                          ),
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

  Widget _buildRowItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              if (value.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}