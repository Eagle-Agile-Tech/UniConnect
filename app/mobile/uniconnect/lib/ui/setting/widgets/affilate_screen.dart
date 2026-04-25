import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../config/assets.dart';
import '../../../routing/routes.dart';
import '../../../utils/enums.dart';
import '../../auth/auth_state_provider.dart';


class AffiliateScreen extends ConsumerStatefulWidget {
  const AffiliateScreen({super.key});

  @override
  ConsumerState<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends ConsumerState<AffiliateScreen> {
  bool _isHidden = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authNotifierProvider).value!.user!;
    final institute = user.institution!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Affiliates',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: institute.verificationStatus ==
          InstitutionVerificationStatus.VERIFIED
          ? ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔐 Secret Code Card (TAPPABLE)
          GestureDetector(
            onTap: () {
              setState(() {
                _isHidden = !_isHidden;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Secret Code',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _isHidden
                        ? '••••••••'
                        : institute.secretCode!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// 👥 Section Title
          Text(
            'Affiliated Experts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          /// 📋 List
          ...List.generate(institute.affiliatedExperts.length, (index) {
            final user = institute.affiliatedExperts[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onTap: () =>
                    context.push(Routes.userProfile(user.id)),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: user.profilePicture != null
                      ? NetworkImage(user.profilePicture!)
                      : AssetImage(Assets.defaultAvatar)
                  as ImageProvider,
                ),
                title: Text(
                  user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          }),
        ],
      )
          : Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Your institution is not verified yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}