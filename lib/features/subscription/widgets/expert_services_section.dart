// lib/features/subscription/widgets/expert_services_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:revboostapp/core/theme/app_colors.dart';
import 'package:revboostapp/features/subscription/widgets/expert_service_card.dart';
import 'package:revboostapp/features/subscription/widgets/expert_contact_form.dart';
import 'package:universal_html/html.dart' as html;

class ExpertServicesSection extends StatelessWidget {
  const ExpertServicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.support_agent,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Custom Solutions?',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Talk to our experts about tailored services for your business',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Services grid - responsive layout with Wrap
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: const [
              ExpertServiceCard(
                title: 'Website Development',
                description: 'Custom business websites designed to convert visitors into customers.',
                icon: Icons.web_outlined,
              ),
              ExpertServiceCard(
                title: 'QR Code Printing',
                description: 'Professional-grade QR code printing for your physical business locations.',
                icon: Icons.qr_code_scanner_outlined,
              ),
              ExpertServiceCard(
                title: 'SEO Optimization',
                description: 'Get found online with our search engine optimization expertise.',
                icon: Icons.search_outlined,
              ),
              ExpertServiceCard(
                title: 'Marketing Strategy',
                description: 'Develop a comprehensive marketing plan for your business growth.',
                icon: Icons.trending_up_outlined,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Contact section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get in Touch',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our experts are ready to help you customize your online presence and review strategy.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  // Contact form - responsive layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 700) {
                        // Mobile layout - stacked form
                        return const ExpertContactForm(isMobile: true);
                      } else {
                        // Desktop layout - side by side form
                        return const ExpertContactForm(isMobile: false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void launchEmail(String email) {
    // Create mailto link
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Expert Services Inquiry&body=I\'m interested in learning more about your services.',
    );
    
    if (kIsWeb) {
      // For web
      html.window.open(emailUri.toString(), '_blank');
    } else {
      // For mobile, you would use url_launcher package
      // launchUrl(emailUri);
    }
  }
}