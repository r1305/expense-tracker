import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/category.dart';

class ExpenseFormDialog extends StatefulWidget {
  final Expense? expense;
  final List<Category> categories;
  const ExpenseFormDialog({super.key, this.expense, required this.categories});

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late String _currency;
  late DateTime _date;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.expense?.description ?? '');
    _amountCtrl = TextEditingController(
        text: widget.expense != null
            ? widget.expense!.amount.toStringAsFixed(2)
            : '');
    _currency = widget.expense?.currency ?? currencies.first;
    _date = widget.expense?.date ?? DateTime.now();
    _categoryId = widget.expense?.categoryId;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Expense(
        id: widget.expense?.id,
        description: _descCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text),
        currency: _currency,
        date: _date,
        categoryId: _categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expense != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar Gasto' : 'Nuevo Gasto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Monto *'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Moneda'),
                items: currencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Sin categoría')),
                  ...widget.categories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title:
                    Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
