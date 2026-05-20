import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const AboutScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF185B43),
        elevation: 0,
        title: const Text('Về chúng tôi'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6ECE7)),
            ),
            child: Column(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F3E7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: Color(0xFF185B43),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nhận Diện Cây Cối',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF1E2722),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ứng dụng hỗ trợ nhận diện cây, tìm hiểu thông tin sinh học và lưu lại hành trình khám phá cây xanh của bạn.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF5F6C65),
                        height: 1.55,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _AboutInfoCard(
            title: 'Sứ mệnh',
            content:
                'Mang trải nghiệm nhận diện cây cối nhanh, trực quan và thân thiện đến với mọi người dùng yêu thiên nhiên.',
          ),
          const SizedBox(height: 18),
          const _AboutInfoCard(
            title: 'Công nghệ',
            content:
                'Flutter cho ứng dụng di động, SQLite cho lưu trữ cục bộ, Supabase cho đồng bộ tài khoản, và AI để hỗ trợ nhận diện cây.',
          ),
          const SizedBox(height: 18),
          const _AboutInfoCard(
            title: 'Phiên bản hiện tại',
            content: '1.0.0',
          ),
        ],
      ),
    );
  }
}

class _AboutInfoCard extends StatelessWidget {
  final String title;
  final String content;

  const _AboutInfoCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1E2722),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5F6C65),
                  height: 1.55,
                ),
          ),
        ],
      ),
    );
  }
}
