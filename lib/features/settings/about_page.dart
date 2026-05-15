import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('关于 WordSnap'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 40),
          // App icon + name + version
          Center(
            child: Image.asset(
              'assets/logo/wordsnap-icon-app.png',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'WordSnap',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          ),
          const SizedBox(height: 32),
          // Info card
          _SectionCard(children: [
            _AboutRow(
              label: '源码',
              value: 'GitHub',
              icon: Icons.open_in_new,
              onTap: () => _openUrl('https://github.com/Jensen-world/WordSnap'),
            ),
            _AboutRow(
              label: '反馈',
              value: 'GitHub Issues',
              icon: Icons.open_in_new,
              onTap: () => _openUrl('https://github.com/Jensen-world/WordSnap/issues'),
            ),
            _AboutRow(
              label: '隐私',
              value: '所有数据仅保存在本机，云端不上传任何信息。',
              icon: Icons.lock,
            ),
          ]),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withDividers(children),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F5)));
      }
    }
    return result;
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  const _AboutRow({required this.label, required this.value, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 14, color: onTap != null ? AppColors.signalBlue : AppColors.inkBlack),
              ),
            ),
            if (icon != null)
              Icon(icon, size: 14, color: onTap != null ? AppColors.signalBlue : const Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
