class CustomerAddress {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String country;

  CustomerAddress({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country = 'India',
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      country: (json['country'] as String?) ?? 'India',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? gstNumber;
  final CustomerAddress address;
  final String? notes;

  CustomerModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.gstNumber,
    required this.address,
    this.notes,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      gstNumber: json['gstNumber'] as String?,
      address: json['address'] != null
          ? CustomerAddress.fromJson(json['address'] as Map<String, dynamic>)
          : CustomerAddress(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'gstNumber': gstNumber,
      'address': address.toJson(),
      'notes': notes,
    };
  }
}
