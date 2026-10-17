import 'package:material_ui/material_ui.dart';
import '../../services/embedded_llm/embedded_model.dart';
import '../../services/embedded_llm/embedded_model_manager.dart';

/// Dialog for manually adding an on-device model by entering its direct download URL.
class AddGgufDialog extends StatefulWidget {
  final String initialFormat;

  const AddGgufDialog({super.key, this.initialFormat = 'all'});

  /// Show the dialog and return the newly added [EmbeddedGgufModel], or null if cancelled.
  static Future<EmbeddedGgufModel?> show(
    BuildContext context, {
    String initialFormat = 'all',
  }) {
    return showDialog<EmbeddedGgufModel>(
      context: context,
      builder: (_) => AddGgufDialog(initialFormat: initialFormat),
    );
  }

  @override
  State<AddGgufDialog> createState() => _AddGgufDialogState();
}

class _AddGgufDialogState extends State<AddGgufDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _mmprojUrlCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _mmprojUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAdd() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final url = _urlCtrl.text.trim();
      final filename = url.split('/').last.split('?').first;
      final mmprojUrl = _mmprojUrlCtrl.text.trim();
      final mmprojFilename = mmprojUrl.isNotEmpty ? mmprojUrl.split('/').last.split('?').first : null;
      
      final model = EmbeddedGgufModel(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        displayName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : filename,
        filename: filename,
        url: url,
        description: 'Custom GGUF model.',
        mmprojUrl: mmprojUrl.isNotEmpty ? mmprojUrl : null,
        mmprojFilename: mmprojFilename,
      );
      
      await EmbeddedModelManager.instance.addCustomModel(model);
      if (mounted) Navigator.of(context).pop(model);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add model: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom;
    final maxContentHeight = availableHeight * 0.6;
    final theme = Theme.of(context);

    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: isMobile ? 12 : 24,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        20,
        isMobile ? 12 : 24,
        16,
      ),
      title: const Row(children: [Icon(Icons.add_link, size: 22), SizedBox(width: 8), Text('Add On-Device Model URL')]),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxContentHeight),
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the direct download URL of a .gguf file. '
                    'You can find GGUF models on HuggingFace.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Display name (optional)',
                      hintText: 'e.g. My Custom Model',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Model download URL *',
                      hintText: 'https://huggingface.co/.../model.gguf',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'URL is required';
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null || !uri.hasScheme) return 'Enter a valid URL';
                      final clean = v.trim().toLowerCase();
                      final isValid = clean.contains('.gguf') || clean.contains('?');
                      if (!isValid) {
                        return 'URL should point to a .gguf model file';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mmprojUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Multimodal projection URL (optional)',
                      hintText: 'https://.../mmproj.gguf',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image_outlined),
                      helperText: 'Only needed for vision models',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _saving ? null : _onAdd,
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add, size: 18),
          label: Text(_saving ? 'Adding...' : 'Add model'),
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary),
        ),
      ],
    );
  }
}
