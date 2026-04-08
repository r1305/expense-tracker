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
    _urlCtrl = TextEditingController(
        text: context.read<SettingsProvider>().baseUrl);
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
    context
        .read<CategoryProvider>()
        .updateRepository(settings.categoryRepository);
    context.read<SalaryProvider>().updateRepository(settings.salaryRepository);
  }

  Future<void> _saveUrl() async {
    final settings = context.read<SettingsProvider>();
    await settings.setBaseUrl(_urlCtrl.text.trim());
    if (!settings.isLocalhost) {
      _swapRepositories(settings);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL guardada')),
      );
    }
  }

  Future<void> _sync() async {
    final settings = context.read<SettingsProvider>();
    final message = await settings.syncToCloud();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Localhost'),
              subtitle: Text(settings.isLocalhost
                  ? 'Los datos se guardan en el dispositivo'
                  : 'Los datos se guardan en la nube'),
              value: settings.isLocalhost,
              onChanged: _onLocalhostChanged,
              secondary: Icon(
                settings.isLocalhost ? Icons.phone_android : Icons.cloud,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Servidor',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://api.ejemplo.com',
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: _saveUrl,
                      child: const Text('Guardar URL'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sincronización',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Envía todos los datos locales al servidor en la nube',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: settings.syncing ? null : _sync,
                      icon: settings.syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(
                          settings.syncing ? 'Sincronizando...' : 'Sincronizar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
