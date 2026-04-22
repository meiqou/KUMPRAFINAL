Map<String, dynamic> parsePhpResponseBody(String body) {
  final result = <String, dynamic>{};
  if (body.trim().isEmpty) {
    return result;
  }

  final flat = Uri.splitQueryString(body);
  for (final entry in flat.entries) {
    _assignValue(result, _parseKeyPath(entry.key), _coerceScalar(entry.value));
  }

  return result;
}

List<String> _parseKeyPath(String key) {
  final segments = <String>[];
  final bracketIndex = key.indexOf('[');
  if (bracketIndex == -1) {
    return [key];
  }

  segments.add(key.substring(0, bracketIndex));
  final bracketPattern = RegExp(r'\[([^\]]*)\]');
  for (final match in bracketPattern.allMatches(key.substring(bracketIndex))) {
    segments.add(match.group(1) ?? '');
  }
  return segments;
}

void _assignValue(dynamic container, List<String> path, dynamic value) {
  if (path.isEmpty) {
    return;
  }

  dynamic current = container;
  for (var index = 0; index < path.length; index++) {
    final segment = path[index];
    final isLast = index == path.length - 1;
    final nextSegment = isLast ? null : path[index + 1];
    final nextIsList = nextSegment != null && _isNumericIndex(nextSegment);

    if (current is Map<String, dynamic>) {
      if (isLast) {
        current[segment] = value;
        return;
      }

      final existing = current[segment];
      if (existing == null) {
        current[segment] = nextIsList ? <dynamic>[] : <String, dynamic>{};
      }
      current = current[segment];
      continue;
    }

    if (current is List) {
      final parsedIndex = segment.isEmpty ? current.length : int.tryParse(segment);
      if (parsedIndex == null) {
        return;
      }

      _ensureListLength(current, parsedIndex);
      if (isLast) {
        current[parsedIndex] = value;
        return;
      }

      final existing = current[parsedIndex];
      if (existing == null) {
        current[parsedIndex] = nextIsList ? <dynamic>[] : <String, dynamic>{};
      }
      current = current[parsedIndex];
    }
  }
}

void _ensureListLength(List<dynamic> list, int index) {
  while (list.length <= index) {
    list.add(null);
  }
}

bool _isNumericIndex(String value) => RegExp(r'^\d+$').hasMatch(value);

dynamic _coerceScalar(String value) {
  final lowered = value.toLowerCase();
  if (lowered == 'true') {
    return true;
  }
  if (lowered == 'false') {
    return false;
  }
  if (RegExp(r'^-?(0|[1-9]\d*)$').hasMatch(value)) {
    return int.parse(value);
  }
  if (RegExp(r'^-?\d+\.\d+$').hasMatch(value)) {
    return double.parse(value);
  }
  return value;
}
