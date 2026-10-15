普通 Center 在 Wrap 的约束下会尽可能占满可用宽度。

```dart
Align(
  alignment: Alignment.center,
  widthFactor: 1,
  child: Text(tag),
)
```

widthFactor: 1 会让 Align 按文字宽度收缩，同时文字仍在 24px 高的标签中垂直居中。flutter analyze 已通过。

```dart

class _Tags extends StatelessWidget {
  const _Tags({required this.displayRole});

  final RoleInfo displayRole;

  @override
  Widget build(BuildContext context) {
    final tags = displayRole.tags ?? const <String>[];
    if (tags.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: .centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (displayRole.age != null && displayRole.age! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              child: Align(
                alignment: Alignment.center,
                widthFactor: 1,
                child: Text(
                  displayRole.age.toString(),
                  style: AppTypography.body3.copyWith(
                    color: AppColors.textOnBrand,
                  ),
                ),
              ),
            ),
          ...tags.map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.tagBg,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              child: Align(
                alignment: Alignment.center,
                widthFactor: 1,
                child: Text(tag, style: AppTypography.body3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

```
