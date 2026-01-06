import 'dart:async';

import 'package:flutter/material.dart';

import '../services/station_repository.dart';

class StationAutocompleteField extends StatefulWidget {
  const StationAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.textStyle,
    this.decoration,
    this.onStationSelected,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final void Function(Map<String, String> station)? onStationSelected;

  @override
  State<StationAutocompleteField> createState() => _StationAutocompleteFieldState();
}

class _StationAutocompleteFieldState extends State<StationAutocompleteField> {
  Timer? _debounce;
  List<Map<String, String>> _suggestions = [];
  bool _show = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    StationRepository.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final v = value.trim();

    if (v.length < 2) {
      setState(() {
        _suggestions = [];
        _show = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 200), () {
      final results = StationRepository.instance.searchLocal(v);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _show = results.isNotEmpty;
      });
    });
  }

  InputDecoration _buildDecoration() {
    final repo = StationRepository.instance;
    final text = widget.controller.text;

    String? helperText;
    if (repo.looksLikeStationCode(text)) {
      helperText = repo.nameForCode(text);
    } else {
      final resolved = repo.resolveCodeFromInput(text);
      if (resolved != null) {
        final name = repo.nameForCode(resolved);
        helperText = name == null || name.isEmpty ? resolved : '$resolved • $name';
      }
    }

    final base = widget.decoration;
    if (base != null) {
      return base.copyWith(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        helperText: helperText,
      );
    }

    return InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      helperText: helperText,
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = _suggestions[index];
          final code = s['code'] ?? '';
          final name = s['name'] ?? '';
          final state = s['state'] ?? '';

          return ListTile(
            dense: true,
            title: Text('$name ($code)'),
            subtitle: state.isEmpty ? null : Text(state),
            onTap: () {
              widget.controller.text = code.toUpperCase();
              widget.onStationSelected?.call(s);
              setState(() {
                _show = false;
                _suggestions = [];
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _loaded;

    return Column(
      children: [
        TextField(
          controller: widget.controller,
          onChanged: enabled ? _onChanged : null,
          decoration: _buildDecoration(),
          style: widget.textStyle,
        ),
        if (_show) _buildSuggestions(),
      ],
    );
  }
}
