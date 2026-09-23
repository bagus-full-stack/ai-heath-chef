class ShoppingItem {
  final String name;
  final bool checked;

  const ShoppingItem({required this.name, this.checked = false});

  ShoppingItem copyWith({bool? checked}) => ShoppingItem(name: name, checked: checked ?? this.checked);

  Map<String, dynamic> toJson() => {'name': name, 'checked': checked};

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        name: json['name'] as String,
        checked: json['checked'] as bool? ?? false,
      );
}
