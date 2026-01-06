part of 'phone_field.dart';

class _PhoneFieldState extends State<PhoneField> {
  late Country _selectedCountry;
  String? validatorMessage;

  final CountryUtil _countryUtil = CountryUtil.instance;

  @override
  void initState() {
    _countryUtil.set(widget.countries ?? CountryData.instance.countries);
    _selectedCountry = _countryUtil.find(widget.country ?? "");

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(widget.phoneBuilder.isNotNull) {
      return widget.phoneBuilder!(
        context,
        _selectedCountry,
        _countryUtil.countries.isNotEmpty,
        _handleChangedCountry,
        _handlePhoneChanged,
        _handleValidate,
        _handleOnSave
      );
    }

    return Field(
      hint: widget.hint ?? "Phone Number",
      controller: widget.controller,
      focus: widget.focusNode,
      keyboard: TextInputType.phone,
      inputDecorationBuilder: widget.inputDecorationBuilder,
      inputConfigBuilder: widget.inputConfigBuilder,
      inputAction: widget.textInputAction ?? TextInputAction.next,
      prefixIcon: _countryUtil.countries.isNotEmpty ? _buildFlagButton() : null,
      suffixIcon: widget.suffixIcon,
      suffixIconConstraints: widget.suffixIconConstraints,
      onChanged: _handlePhoneChanged,
      validator: _handleValidate,
      onSaved: _handleOnSave,
      onTapOutside: widget.onTapOutside,
      label: widget.label,
      cursorWidth: widget.cursorWidth,
      spacing: widget.spacing,
      borderRadius: widget.borderRadius,
      cursorHeight: widget.cursorHeight,
      cursorErrorColor: widget.cursorErrorColor,
      cursorColor: widget.cursorColor,
      fillColor: widget.fillColor,
      enabled: widget.enabled,
      needLabel: widget.needLabel,
      replaceHintWithLabel: widget.replaceHintWithLabel,
      padding: widget.padding
    );
  }

  Widget _buildFlagButton() {
    if(widget.flagBuilder.isNotNull) {
      return widget.flagBuilder!(context, _selectedCountry, _handleChangedCountry);
    }

    return Padding(
      padding: widget.flagButtonPadding ?? EdgeInsets.only(right:3),
      child: _defaultFlagButton()
    );
  }

  Widget _defaultFlagButton() {
    BoxDecoration decoration = widget.flagButtonDecoration ?? BoxDecoration(
      border: Border(right: BorderSide(color: Theme.of(context).primaryColor)),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        bottomLeft: Radius.circular(10)
      )
    );

    return Padding(
      padding: widget.flagButtonBodyPadding ?? EdgeInsets.only(left: 2),
      child: Material(
        color: widget.flagButtonColor ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: decoration.borderRadius as BorderRadius?,
        child: InkWell(
          borderRadius: decoration.borderRadius as BorderRadius?,
          onTap: _changeCountry,
          child: DecoratedBox(
            decoration: decoration,
            child: Padding(
              padding: widget.flagButtonBoxPadding ?? EdgeInsets.all(Sizing.space(9)),
              child: Row(
                spacing: widget.flagSpacing ?? 3,
                mainAxisSize: widget.flagMainAxisSize ?? MainAxisSize.min,
                mainAxisAlignment: widget.flagMainAxisAlignment ?? MainAxisAlignment.center,
                crossAxisAlignment: widget.flagCrossAxisAlignment ?? CrossAxisAlignment.center,
                children: <Widget>[
                  CountryUtil.instance.getFlag(
                    _selectedCountry,
                    useFlagEmoji: widget.useFlagEmoji,
                    size: widget.flagSize
                  ),
                  TextBuilder(
                    text: '+${_selectedCountry.dialCode}',
                    size: widget.flagTextSize ?? Sizing.font(14),
                    color: widget.flagTextColor ?? Theme.of(context).primaryColor,
                  )
                ],
              ),
            ),
          ),
        ),
      )
    );
  }

  void _changeCountry() {
    if(widget.onChangeCountryClicked.isNotNull) {
      widget.onChangeCountryClicked!(_handleChangedCountry);
    }
  }

  void _handleChangedCountry(Country country) {
    if(mounted) {
      setState(() {
        _selectedCountry = country;
      });

      if(widget.onCountryChanged.isNotNull) {
        widget.onCountryChanged!(country);
      }
    }
  }

  void _handlePhoneChanged(String value) async {
    final phoneNumber = PhoneNumber(
      countryISOCode: _selectedCountry.code,
      countryCode: '+${_selectedCountry.dialCode}',
      number: value,
    );

    if(widget.validator.isNotNull) {
      validatorMessage = await widget.validator!(phoneNumber);
    }
    
    if(widget.onChanged.isNotNull) {
      widget.onChanged!(phoneNumber);
    }
  }

  String? _handleValidate(String? value) {
    if (!widget.disableLengthCheck && value.isNotNull) {
      return value!.length.isGtOrEt(_selectedCountry.min) && value.length.isLtOrEt(_selectedCountry.max)
          ? null
          : widget.phoneNumberErrorMessage;
    }

    return validatorMessage;
  }

  void _handleOnSave(String? value) {
    if(value.isNotNull) {
      final phoneNumber = PhoneNumber(
        countryISOCode: _selectedCountry.code,
        countryCode: '+${_selectedCountry.dialCode}',
        number: value!,
      );

      if(widget.onSaved.isNotNull) {
        widget.onSaved!(phoneNumber);
      }
    }
  }
}