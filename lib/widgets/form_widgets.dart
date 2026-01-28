import 'package:flutter/material.dart';

Widget buildSectionTitle(String title) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Text(
    title,
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.blue,
    ),
  ),
);

Widget buildNameField(String label, TextEditingController controller) =>
    buildTextField(
      label,
      controller,
      hint: 'Enter $label',
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $label';
        if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
          return 'Only alphabets allowed';
        }
        return null;
      },
    );

Widget buildEmailField(TextEditingController controller) => buildTextField(
  'Email',
  controller,
  keyboardType: TextInputType.emailAddress,
  hint: 'Enter your email',
  validator: (value) {
    if (value == null || value.isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,6}$');
    return emailRegex.hasMatch(value) ? null : 'Enter a valid email';
  },
);

Widget buildPhoneFieldWithDropdown({
  required String label,
  required List<String> countryCodes,
  required String selectedCode,
  required Function(String?) onCodeChanged,
  required TextEditingController controller,
  TextEditingController? checkDuplicateWith,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: selectedCode,
            items:
                countryCodes
                    .map(
                      (code) =>
                          DropdownMenuItem(value: code, child: Text(code)),
                    )
                    .toList(),
            onChanged: onCodeChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Code',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: buildTextField(
            label,
            controller,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            hint: 'XXXXXXXXXX',
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter $label';
              if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
                return 'Invalid phone number';
              }
              if (checkDuplicateWith != null &&
                  value == checkDuplicateWith.text) {
                return 'Numbers must differ';
              }
              return null;
            },
          ),
        ),
      ],
    ),
  );
}

Widget buildAddressField(TextEditingController controller) => buildTextField(
  'Address',
  controller,
  maxLines: 4,
  maxLength: 250,
  hint: 'House No, Street, Area...',
);

Widget buildPincodeField(TextEditingController controller) => buildTextField(
  'Pincode',
  controller,
  keyboardType: TextInputType.number,
  maxLength: 6,
  hint: 'Enter 6-digit pincode',
);

Widget buildDatePickerField(
  BuildContext context,
  TextEditingController controller,
) {
  return GestureDetector(
    onTap: () async {
      FocusScope.of(context).unfocus();
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2005),
        firstDate: DateTime(1980),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        // Format date as YYYY-MM-DD
        String formattedDate =
            "${picked.toLocal().year}-"
            "${picked.toLocal().month.toString().padLeft(2, '0')}-"
            "${picked.toLocal().day.toString().padLeft(2, '0')}";
        controller.text = formattedDate;
      }
    },
    child: AbsorbPointer(
      child: buildTextField(
        'Date of Birth',
        controller,
        hint: 'Select date (YYYY-MM-DD)',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a date of birth';
          }
          // Optional: Add date format validation
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
            return 'Invalid date format';
          }
          return null;
        },
      ),
    ),
  );
}

Widget buildDropdownField(
  String label,
  List<String> items,
  Function(String?) onChanged, {
  String? initialValue,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: DropdownButtonFormField<String>(
      value: initialValue,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: label,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select $label' : null,
    ),
  );
}

Widget buildTextField(
  String label,
  TextEditingController controller, {
  String? hint,
  int maxLines = 1,
  int? maxLength,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    ),
  );
}
