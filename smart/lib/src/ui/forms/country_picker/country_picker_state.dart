part of 'country_picker.dart';

class _CountryPickerState extends State<CountryPicker> {
  late List<Country> _filteredCountries;
  late List<Country> _countries;
  Country? _selectedCountry;

  @override
  void initState() {
    _selectedCountry = widget.selected;
    _filteredCountries = widget.countries.isEmpty ? CountryData.instance.countries : widget.countries;
    _countries = widget.countries.isEmpty ? CountryData.instance.countries : widget.countries;

    super.initState();
  }

  @override
  void didUpdateWidget(covariant CountryPicker oldWidget) {
    if(oldWidget.selected != widget.selected) {
      setState(() {
        _selectedCountry = widget.selected;
      });
    } else if(oldWidget.countries != widget.countries) {
      setState(() {
        _filteredCountries = widget.countries.isEmpty ? CountryData.instance.countries : widget.countries;
        _countries = widget.countries.isEmpty ? CountryData.instance.countries : widget.countries;
      });
    } else {
      setState(() {});
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if(widget.isDialog) {
      return _buildWithDialog(context);
    } else {
      return _buildWithBottomSheet(context);
    }
  }

  /// Dialog option
  Widget _buildWithDialog(BuildContext context) {
    return Dialog(
      insetPadding: widget.dialogPadding ?? EdgeInsets.symmetric(
        vertical: Sizing.space(40),
        horizontal: Sizing.space(20)
      ),
      shape: widget.dialogShape,
      insetAnimationDuration: widget.dialogAnimationDuration ?? const Duration(milliseconds: 100),
      insetAnimationCurve: widget.dialogAnimationCurve ?? Curves.decelerate,
      backgroundColor: widget.backgroundColor ?? Theme.of(context).splashColor,
      surfaceTintColor: widget.surfaceTintColor ?? Theme.of(context).splashColor,
      child: Container(
        padding: widget.bodyPadding ?? EdgeInsets.all(Sizing.space(10)),
        child: Column(
          spacing: widget.bodySpacing ?? 20,
          mainAxisSize: widget.mainAxisSize ?? MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if(widget.indicator.isNotNull) ...[
              widget.indicator!
            ],
            if(widget.showSearchFormField) ...[
              _buildSearchFormField(),
            ],
            _buildCountryListView(context)
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFormField() {
    if(widget.searchFormFieldBuilder case final searchFormFieldBuilder?) {
      return searchFormFieldBuilder(_search);
    }

    final field = Field(
      hint: widget.placeholder ?? "Search Country/Region",
      borderRadius: widget.formBorderRadius ?? Sizing.space(20),
      suffixIcon: widget.icon ?? Icon(Icons.search),
      inputConfigBuilder: widget.inputConfigBuilder,
      inputDecorationBuilder: widget.decorationConfigBuilder,
      onChanged: _search,
      fillColor: widget.formBackgroundColor,
    );

    if(widget.searchFieldBuilder case final searchFieldBuilder?) {
      return searchFieldBuilder(() => field, _search);
    }

    return field;
  }

  void _search(String value) {
    _filteredCountries = value.isNumeric
        ? _countries.where((country) => country.dialCode.contains(value)).toList()
        : _countries.where((country) => country.name.containsIgnoreCase(value)).toList();

    if(mounted) setState(() { });
  }

  void handleSelect(Country country, bool shouldPopBack) {
    setState(() => _selectedCountry = country);
    
    if(widget.onChanged case final onChanged?) {
      onChanged(country);
    }

    // Only pop if you want the sheet to close immediately
    if (shouldPopBack) Navigator.of(context).pop(country);
  }

  Widget _buildCountryListView(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filteredCountries.length,
        separatorBuilder: (context, index) {
          Country country = _filteredCountries[index];

          ItemMetadata<Country> metadata = ItemMetadata(
            isSelected: country.name.equalsIgnoreCase(_selectedCountry?.name ?? ""),
            isLast: index.equals(_filteredCountries.length - 1),
            isFirst: index.equals(0),
            index: index,
            totalItems: _filteredCountries.length,
            item: country
          );

          if(widget.itemSeparatorBuilder case final itemSeparatorBuilder?) {
            return itemSeparatorBuilder(context, metadata, (value) => handleSelect(country, false));
          }

          return Spacing.vertical(widget.itemSeparatorSize ?? 10);
        },
        itemBuilder: (ctx, index) {
          Country country = _filteredCountries[index];

          ItemMetadata<Country> metadata = ItemMetadata(
            isSelected: country.name.equalsIgnoreCase(_selectedCountry?.name ?? ""),
            isLast: index.equals(_filteredCountries.length - 1),
            isFirst: index.equals(0),
            index: index,
            totalItems: _filteredCountries.length,
            item: country
          );

          if(widget.itemBuilder case final itemBuilder?) {
            return itemBuilder(context, metadata, (value) => handleSelect(country, value));
          }

          return SmartButton(
            tab: ButtonView(
              header: country.name,
              body: '+${country.dialCode}',
              imageWidget: CountryUtil.instance.getFlag(
                country,
                useFlagEmoji: widget.useFlagEmoji,
                size: widget.itemFlagSize
              )
            ),
            headerTextSize: widget.itemNameSize,
            bodyTextSize: widget.itemDialCodeSize,
            color: widget.itemNameColor,
            bodyColor: widget.itemDialCodeColor,
            fontWeight: widget.itemNameWeight,
            bodyWeight: widget.itemDialCodeWeight,
            backgroundColor: widget.itemBackgroundColor,
            notification: TextBuilder(
              text: country.code,
              size: Sizing.font(widget.itemCodeSize ?? 20),
              weight: widget.itemCodeWeight ?? FontWeight.w700,
              color: widget.itemCodeColor ?? Theme.of(context).primaryColor
            ),
            onTap: () => handleSelect(country, true),
          );
        }
      ),
    );
  }

  Widget _buildWithBottomSheet(BuildContext context) {
    return ModalBottomSheet(
      useSafeArea: (config) => config.copyWith(top: true),
      sheetPadding: widget.dialogPadding ?? EdgeInsets.all(16),
      padding: widget.bodyPadding ?? EdgeInsets.all(10),
      borderRadius: widget.bottomSheetBorderRadius ?? BorderRadius.circular(24),
      backgroundColor: widget.backgroundColor ?? Theme.of(context).splashColor,
      height: widget.height,
      uiConfig: widget.uiConfig,
      useDefaultBorderRadius: widget.useDefaultBorderRadius,
      child: Column(
        spacing: widget.bodySpacing ?? 20,
        mainAxisSize: widget.mainAxisSize ?? MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if(widget.indicator case final indicator?) ...[
            indicator
          ],
          if(widget.showSearchFormField) ...[
            _buildSearchFormField(),
          ],
          _buildCountryListView(context)
        ],
      ),
    );
  }
}
