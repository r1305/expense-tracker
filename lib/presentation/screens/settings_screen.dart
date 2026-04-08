import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/salary_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: context.read<SettingsProvider>().baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _onLocalhostChanged(bool value) {
    final settings = context.read<SettingsProvider>();
    settings.setLocalhost(value);
    _swapRepositories(settings);
  }

  void _swapRepositories(SettingsProvider settings) {
    context.read<ExpenseProvider>().updateRepository(settings.expenseRepository);
    context.read<CategoryProvider>().updateRepository(settings.categoryRepository);
    context.read<SalaryProvider>().updateRepository(settings.salaryRepository);
  }

  Future<void> _saveUrl() async {
    final settings = context.read<SettingsProvider>();
    await settings.setBaseUrl(_urlCtrl.text.trim());
    if (!settings.isLocalhost) _swapRepositories(settings);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), content: const Text('URL guardada')));
  }

  Future<void> _sync() async {
    final settings = context.read<SettingsProvider>();
    final message = await settings.syncToCloud();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text('Ajustes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
              child: SwitchListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Almacenamiento local', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(settings.isLocalhost ? 'Datos en el dispositivo' : 'Datos en la nube', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                value: settings.isLocalhost,
                onChanged: _onLocalhostChanged,
                secondary: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
                  child: Icon(settings.isLocalhost ? Icons.phone_android_rounded : Icons.cloud_rounded, color: cs.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Servidor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('URL del backend remoto', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://api.ejemplo.com', prefixIcon: Icon(Icons.link_rounded)),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: _saveUrl, child: const Text('Guardar URL'))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sync_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Sincronización', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Envía datos locales al servidor', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: settings.syncing ? null : _sync,
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: cs.primary),
                      icon: settings.syncing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(settings.syncing ? 'Sincronizando...' : 'Sincronizar ahora'),
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
}
