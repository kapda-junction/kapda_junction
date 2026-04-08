import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../bloc/categories/categories_bloc.dart';
import '../../widgets/common/admin_drawer.dart';
import '../../../domain/entities/category.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CategoriesBloc>()..add(CategoriesLoadRequested()),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  void _showForm(BuildContext context, {Category? category}) {
    final state = context.read<CategoriesBloc>().state;
    final all = state is CategoriesLoaded ? state.categories : <Category>[];
    final bloc = context.read<CategoriesBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _CategoryFormSheet(category: category, allCategories: all),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "$name"? Products in this category may be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CategoriesBloc>().add(CategoryDeleteRequested(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          FilledButton.icon(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocConsumer<CategoriesBloc, CategoriesState>(
        listener: (context, state) {
          if (state is CategorySaveSuccess) {
            context.read<CategoriesBloc>().add(CategoriesLoadRequested());
          } else if (state is CategoriesFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
            );
          }
        },
        builder: (context, state) {
          if (state is CategoriesLoading) return const Center(child: CircularProgressIndicator());
          if (state is CategoriesFailure) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(state.message),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<CategoriesBloc>().add(CategoriesLoadRequested()),
                child: const Text('Retry'),
              ),
            ]));
          }
          if (state is CategoriesLoaded) {
            if (state.categories.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.category_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  const Text('No categories yet.'),
                ]),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = state.categories[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.isActive
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(c.name[0].toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  ),
                  title: Text(c.name),
                  subtitle: c.parentName != null
                      ? Text('Under: ${c.parentName}',
                          style: Theme.of(context).textTheme.bodySmall)
                      : Text('Sort: ${c.sortOrder}',
                          style: Theme.of(context).textTheme.bodySmall),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Switch(
                      value: c.isActive,
                      onChanged: (v) => context.read<CategoriesBloc>()
                          .add(CategoryToggleActiveRequested(c.id, v)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showForm(context, category: c),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error),
                      onPressed: () => _confirmDelete(context, c.id, c.name),
                    ),
                  ]),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Full-featured Category Form Sheet ───────────────────────────────────────

class _CategoryFormSheet extends StatefulWidget {
  final Category? category;
  final List<Category> allCategories;

  const _CategoryFormSheet({this.category, required this.allCategories});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();

  String? _parentId;
  bool _isActive = true;
  bool _saving = false;

  // Top-level categories only (for parent selection)
  List<Category> get _topLevel =>
      widget.allCategories.where((c) => c.parentId == null).toList();

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    if (cat != null) {
      _nameCtrl.text = cat.name;
      _slugCtrl.text = cat.slug;
      _descCtrl.text = cat.description ?? '';
      _sortCtrl.text = cat.sortOrder.toString();
      _parentId = cat.parentId;
      _isActive = cat.isActive;
    } else {
      _sortCtrl.text = '0';
    }

    // Auto-generate slug from name
    _nameCtrl.addListener(() {
      if (_slugCtrl.text.isEmpty || widget.category == null) {
        final slug = _nameCtrl.text
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
            .trim()
            .replaceAll(RegExp(r'\s+'), '-');
        _slugCtrl.text = slug;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'slug': _slugCtrl.text.trim().isEmpty ? null : _slugCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'parent': _parentId,
      'sortOrder': int.tryParse(_sortCtrl.text) ?? 0,
      'isActive': _isActive,
    };
    context.read<CategoriesBloc>().add(CategorySaveRequested(
      id: widget.category?.id,
      data: data,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                isEdit ? 'Edit Category' : 'Add Category',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              // Slug
              TextFormField(
                controller: _slugCtrl,
                decoration: const InputDecoration(
                  labelText: 'Slug',
                  hintText: 'auto-generated if empty',
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 12),

              // Parent Category
              DropdownButtonFormField<String>(
                initialValue: _parentId,
                decoration: const InputDecoration(labelText: 'Parent Category'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('— None (Top level) —'),
                  ),
                  ..._topLevel
                      .where((c) => c.id != widget.category?.id)
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _parentId = v),
              ),
              const SizedBox(height: 12),

              // Sort Order
              TextFormField(
                controller: _sortCtrl,
                decoration: const InputDecoration(labelText: 'Sort Order'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),

              // isActive
              CheckboxListTile(
                title: const Text('Visible to customers'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
