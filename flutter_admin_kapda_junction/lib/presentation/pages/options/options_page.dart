import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../bloc/options/options_bloc.dart';
import '../../widgets/common/admin_drawer.dart';

class OptionsPage extends StatelessWidget {
  const OptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OptionsBloc>()..add(OptionsLoadRequested()),
      child: const _OptionsView(),
    );
  }
}

class _OptionsView extends StatelessWidget {
  const _OptionsView();

  void _showColorForm(BuildContext context, {String? id, String? currentName}) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'New Color' : 'Edit Color'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Color Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              if (id != null) {
                context.read<OptionsBloc>().add(ColorUpdateRequested(id, ctrl.text.trim()));
              } else {
                context.read<OptionsBloc>().add(ColorCreateRequested(ctrl.text.trim()));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSizeForm(BuildContext context, {String? id, String? currentName}) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'New Size' : 'Edit Size'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Size Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              if (id != null) {
                context.read<OptionsBloc>().add(SizeUpdateRequested(id, ctrl.text.trim()));
              } else {
                context.read<OptionsBloc>().add(SizeCreateRequested(ctrl.text.trim()));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AdminDrawer(),
        appBar: AppBar(
          title: const Text('Colors & Sizes'),
          bottom: const TabBar(tabs: [Tab(text: 'Colors'), Tab(text: 'Sizes')]),
        ),
        body: BlocConsumer<OptionsBloc, OptionsState>(
          listener: (context, state) {
            if (state is OptionsFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Theme.of(context).colorScheme.error),
              );
            }
          },
          builder: (context, state) {
            if (state is OptionsLoading) return const Center(child: CircularProgressIndicator());
            if (state is OptionsLoaded) {
              return TabBarView(children: [
                // Colors tab
                Scaffold(
                  floatingActionButton: FloatingActionButton.small(
                    onPressed: () => _showColorForm(context),
                    child: const Icon(Icons.add),
                  ),
                  body: state.colors.isEmpty
                      ? const Center(child: Text('No colors yet.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: state.colors.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final c = state.colors[i];
                            return ListTile(
                              leading: CircleAvatar(child: Text(c.name[0].toUpperCase())),
                              title: Text(c.name),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showColorForm(context, id: c.id, currentName: c.name),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                  onPressed: () => context.read<OptionsBloc>().add(ColorDeleteRequested(c.id)),
                                ),
                              ]),
                            );
                          },
                        ),
                ),
                // Sizes tab
                Scaffold(
                  floatingActionButton: FloatingActionButton.small(
                    onPressed: () => _showSizeForm(context),
                    child: const Icon(Icons.add),
                  ),
                  body: state.sizes.isEmpty
                      ? const Center(child: Text('No sizes yet.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: state.sizes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final s = state.sizes[i];
                            return ListTile(
                              leading: CircleAvatar(child: Text(s.name[0].toUpperCase())),
                              title: Text(s.name),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showSizeForm(context, id: s.id, currentName: s.name),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                  onPressed: () => context.read<OptionsBloc>().add(SizeDeleteRequested(s.id)),
                                ),
                              ]),
                            );
                          },
                        ),
                ),
              ]);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
