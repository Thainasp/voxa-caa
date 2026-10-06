import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxa/core/theme/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contentBackground,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.headerGreen,
            padding: const EdgeInsets.only(
              top: 45,
              bottom: 25,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Termos E Condições',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleColor,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                transform: Matrix4.translationValues(0.0, -15.0, 0.0),
                decoration: const BoxDecoration(
                  color: AppColors.contentBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Est Fugiat Assumenda Aut Reprehenderit',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Lorem ipsum dolor sit amet. Et odio officia aut voluptate internos est '
                      'omnis vitae ut architecto sunt non tenetur fuga ut provident vero. '
                      'Quo aspernatur facere et consectetur ipsum et facere corrupti est '
                      'asperiores facere. Est fugiat assumenda aut reprehenderit voluptatem sed.\n\n'
                      '1. Ea voluptates omnis aut sequi sequi.\n'
                      '2. Est dolore quae in aliquid ducimus et autem repellendus.\n'
                      '3. Aut ipsum quis qui porro quasi aut minus placeat!\n'
                      '4. Sit consequatur neque ab vitae facere.\n\n'
                      'Aut quidem accusantium nam alias autem eum officiis placeat et '
                      'omnis autem id officiis perspiciatis qui corrupti officia eum aliquam '
                      'provident. Eum voluptas error et optio dolorum cum molestiae nobis et '
                      'odit molestiae quo magnam impedit sed fugiat nihil non nihil vitae.',
                      textAlign: TextAlign.justify,
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Read the terms and conditions in more detail at\nwww.finwiseapp.de',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.fieldFillColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.home_outlined,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
