class CompanyAddress {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String country;

  CompanyAddress({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country = 'India',
  });

  factory CompanyAddress.fromJson(Map<String, dynamic> json) {
    return CompanyAddress(
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

class BankDetails {
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? branchAddress;

  BankDetails({
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.branchAddress,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      branchAddress: json['branchAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branchAddress': branchAddress,
    };
  }
}

class CompanyModel {
  final String id;
  final String companyName;
  final String? gstNumber;
  final String? phone;
  final String? email;
  final String? website;
  final CompanyAddress address;
  final BankDetails bankDetails;
  final String? logoUrl;
  final String? signatureUrl;
  final String? stampUrl;
  final String defaultTemplate;

  CompanyModel({
    required this.id,
    required this.companyName,
    this.gstNumber,
    this.phone,
    this.email,
    this.website,
    required this.address,
    required this.bankDetails,
    this.logoUrl,
    this.signatureUrl,
    this.stampUrl,
    this.defaultTemplate = 'modern',
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      gstNumber: json['gstNumber'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      address: json['address'] != null
          ? CompanyAddress.fromJson(json['address'] as Map<String, dynamic>)
          : CompanyAddress(),
      bankDetails: json['bankDetails'] != null
          ? BankDetails.fromJson(json['bankDetails'] as Map<String, dynamic>)
          : BankDetails(),
      logoUrl: json['logo'] != null ? json['logo']['url'] as String? : null,
      signatureUrl: json['signature'] != null ? json['signature']['url'] as String? : null,
      stampUrl: json['stamp'] != null ? json['stamp']['url'] as String? : null,
      defaultTemplate: json['defaultTemplate'] as String? ?? 'modern',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'gstNumber': gstNumber,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address.toJson(),
      'bankDetails': bankDetails.toJson(),
      'defaultTemplate': defaultTemplate,
    };
  }
}
