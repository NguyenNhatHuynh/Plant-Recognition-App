import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const FeedbackScreen(),
    );
  }

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      _showSnackBar('Vui lòng nhập tiêu đề và nội dung phản hồi.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final uri = Uri(
      scheme: 'mailto',
      path: 'xoandev.contact@gmail.com',
      queryParameters: <String, String>{
        'subject': '[Phan hoi app cay] $subject',
        'body': message,
      },
    );

    try {
      final launched = await launchUrl(uri);
      if (!mounted) {
        return;
      }
      if (launched) {
        _showSnackBar('Đã mở ứng dụng email để gửi phản hồi.');
      } else {
        _showSnackBar('Không thể mở ứng dụng email trên thiết bị này.');
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Đã xảy ra lỗi khi mở ứng dụng email.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
        title: const Text('Phản hồi'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Chia sẻ góp ý để ứng dụng ngày càng tốt hơn.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5F6C65),
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE6ECE7)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _subjectController,
                  decoration: _inputDecoration(
                    label: 'Tiêu đề phản hồi',
                    icon: Icons.title_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _messageController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: _inputDecoration(
                    label: 'Nội dung phản hồi',
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    icon: const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting ? 'Đang xử lý...' : 'Gửi phản hồi',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185B43),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7F9F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFDDE6E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF185B43),
          width: 1.4,
        ),
      ),
    );
  }
}
