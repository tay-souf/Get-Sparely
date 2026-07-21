import 'dart:developer';

import 'package:country_picker/country_picker.dart';
import 'package:eClassify/ui/screens/location/helpers/debounce_search_mixin.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';

class PhoneInput extends StatefulWidget {
  const PhoneInput({
    required this.controller,
    this.readOnly = false,
    super.key,
  });

  final PhoneInputController controller;
  final bool readOnly;

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> with DebounceSearchMixin {
  late final TextEditingController _controller;
  String phoneCode = Constant.defaultPhoneCode;
  late CountryWithPhoneCode country;

  final countries = CountryManager().countries;

  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    setCountry(widget.controller.regionCode);
    phoneCode = country.phoneCode;
    final formatted = formatNumberSync(
      widget.controller.phoneNumber,
      country: country,
      inputContainsCountryCode: false,
    );
    _controller = TextEditingController(text: formatted);
    validate(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void setCountry(String countryCode) {
    country = countries.firstWhere(
      (element) =>
          element.countryCode.toLowerCase() == countryCode.toLowerCase(),
      orElse: () => CountryWithPhoneCode.us(),
    );
  }

  Future<void> validate(String? value) async {
    if (value == null || value.isEmpty) {
      _isValid = false;
    } else {
      final result = await getFormattedParseResult(value, country);
      log('${result?.e164} ${country.countryName}');
      if (result == null) {
        _isValid = false;
      } else {
        final phoneCode = country.phoneCode;
        // Increase the length by 1 to account for '+'.
        final number = result.e164.substring(phoneCode.length + 1);
        widget.controller.phoneCode = phoneCode;
        widget.controller.phoneNumber = number;
        widget.controller.regionCode = country.countryCode;
        widget.controller.formattedNumber = result.formattedNumber;
        _isValid = true;
      }
    }
  }

  @override
  Duration get debounceDuration => const Duration(milliseconds: 200);

  @override
  void onDebouncedSearch(String? value) async => validate(value);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      textAlignVertical: TextAlignVertical.center,
      keyboardType: TextInputType.number,
      readOnly: widget.readOnly,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: context.font.large,
        color: context.color.textDefaultColor,
      ),
      validator: (value) {
        return _isValid
            ? null
            : 'pleaseEnterValidPhoneNumber'.translate(context);
      },
      inputFormatters: [
        LibPhonenumberTextFormatter(
          country: country,
          shouldKeepCursorAtEndOfInput: false,
        ),
      ],
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 12),
        filled: true,
        fillColor: context.color.secondaryColor,
        hintText: country.phoneMaskMobileInternational
            .substring(country.phoneCode.length + 1)
            .replaceAll('0', 'X'),
        hintStyle: TextStyle(color: context.color.textLightColor),
        prefix: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: context.color.textDefaultColor,
          ),
          onPressed: () {
            if (widget.readOnly) return;
            showCountryPicker(
              context: context,
              showPhoneCode: true,
              onSelect: (country) {
                setState(() {
                  phoneCode = country.phoneCode;
                  setCountry(country.countryCode);
                });
                log('${this.country}');
                _controller.clear();
              },
            );
          },
          child: Text(
            '${phoneCode.startsWith('+') ? phoneCode : '+$phoneCode'}',
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.5,
            color: context.color.territoryColor,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.5,
            color: context.color.textLightColor.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 1.5, color: context.color.borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
    );
  }
}

class PhoneInputController {
  PhoneInputController();

  factory PhoneInputController.empty() => PhoneInputController()..clear();

  String _phoneCode = Constant.defaultPhoneCode;
  String get phoneCode => _phoneCode;

  set phoneCode(String? value) {
    if (value == null) return;
    _phoneCode = value;
  }

  String _phoneNumber = '';
  String get phoneNumber => _phoneNumber;

  set phoneNumber(String? value) {
    if (value == null) return;
    _phoneNumber = value;
  }

  String _regionCode = Constant.defaultCountryCode;

  String get regionCode => _regionCode;

  set regionCode(String? value) {
    if (value == null) return;
    _regionCode = value;
  }

  String _formattedNumber = '';

  String get formattedNumber => _formattedNumber;

  set formattedNumber(String? value) {
    if (value == null) return;
    _formattedNumber = value;
  }

  void clear() {
    _phoneNumber = '';
    _phoneCode = Constant.defaultPhoneCode;
    _regionCode = Constant.defaultCountryCode;
  }

  String get value => '+$phoneCode $_phoneNumber';

  @override
  String toString() {
    return 'PhoneInputController{_phoneCode: $_phoneCode, _phoneNumber: $_phoneNumber}';
  }
}
