import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/category.dart';
import '../providers/category_provider.dart';

class CategoryManagerDialog extends StatefulWidget {
  const CategoryManagerDialog({super.key});

  @override
  State<CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<CategoryManagerDialog> {
  late final CategoryProvider _prov;

  @override
  void initState() {
    super.initState();
    _prov = context.read<CategoryProvider>();
    _prov.addListener(_onChanged);
  }

  @override
  void dispose() {
    _prov.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _showForm({Category? category}) async {
    final ctrl = TextEditingController(text: category?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(category != null ? 'Editar Categoría' : 'Nueva Categoría'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name == null) return;
    if (category != null) {
      await _prov.update(Category(id: category.id, name: name));
    } else {
      await _prov.add(Category(name: name));
    }
  }

  Future<void> _delete(Category cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
            '¿Eliminar "${cat.name}"? Los gastos asociados quedarán sin categoría.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí')),
        ],
      ),
    );
    if (ok == true) {
      await _prov.remove(cat.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _prov.categories;
    return AlertDialog(
      title: const Text('Categorías'),
      content: SizedBox(
        width: double.maxFinite,
        child: categories.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No hay categorías')),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  return ListTile(
                    title: Text(cat.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showForm(category: cat)),
                        IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _delete(cat)),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar')),
        FilledButton.icon(
          onPressed: _showForm,
          icon: const Icon(Icons.add),
          label: const Text('Agregar'),
        ),
      ],
    );
  }
}
