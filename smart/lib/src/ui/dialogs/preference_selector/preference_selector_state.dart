part of 'preference_selector.dart';

class _PreferenceSelectorState extends State<PreferenceSelector> {
  late Gender _gender;
  late ThemeType _theme;
  late ScheduleTime _schedule;
  late PreferenceOption _preference;
  late SecurityType _security;

  final bool _isLoading = false;

  @override
  void initState() {
    _gender = widget.gender;
    _theme = widget.theme;
    _schedule = widget.schedule;
    _preference = widget.preference;
    _security = widget.security;

    super.initState();
  }

  void _onSave() async {
    if(widget.onChanged.isNotNull) {
      bool result = await widget.onChanged(_gender, _theme, _preference, _schedule, _security);
      _refresh<bool>(current: _isLoading, update: result);

      Navigator.pop(context);
    } else {
      Navigator.pop(context);
    }
  }

  void _refresh<T>({required T current, required T update}) {
    setState(() {
      current = update;
    });
  }

  @protected
  bool get showButton => _gender.notEquals(widget.gender)
      || _preference.notEquals(widget.preference)
      || _schedule.notEquals(widget.schedule)
      || _theme.notEquals(widget.theme)
      || _security.notEquals(widget.security);

  @protected
  Color get textColor => widget.textColor ?? Theme.of(context).primaryColorLight;

  @protected
  Color get selectedIconColor => widget.selectedIconColor ?? Theme.of(context).primaryColorLight;

  @protected
  Widget get customSelected => widget.customSelected ?? Icon(
    Icons.playlist_add_check_circle_rounded,
    color: selectedIconColor
  );

  @override
  Widget build(BuildContext context) {
    return ModalBottomSheet(
      useSafeArea: widget.useSafeArea,
      uiConfig: widget.uiConfig,
      backgroundColor: widget.backgroundColor,
      child: SingleChildScrollView(
        child: Column(
          spacing: 10,
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.custom ?? SizedBox.shrink(),
            Center(
              child: TextBuilder(
                text: widget.header,
                color: Theme.of(context).primaryColor,
                size: Sizing.font(24),
                weight: FontWeight.bold,
              ),
            ),
            if(widget.type.isTheme) ...[
              theme()
            ],
            if(widget.type.isGender) ...[
              gender()
            ],
            if(widget.type.isSecurity) ...[
              security()
            ],
            if(widget.type.isSchedule) ...[
              schedule()
            ],
            if(widget.type.isPreference) ...[
              preference()
            ],
            if(showButton) ...[
              InteractiveButton(
                text: "Save",
                borderRadius: 24,
                width: MediaQuery.sizeOf(context).width,
                textSize: Sizing.font(14),
                buttonColor: Theme.of(context).primaryColorDark,
                textColor: Theme.of(context).scaffoldBackgroundColor,
                loading: _isLoading,
                onClick: _onSave,
              )
            ]
          ],
        ),
      )
    );
  }

  @protected
  Widget gender() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: Gender.values.map((gender) {
        bool isSelected = _gender.equals(gender);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: item(
            isSelected: isSelected,
            onTap: () => _refresh<Gender>(current: _gender, update: gender),
            child: Row(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextBuilder(
                    text: gender.value,
                    size: Sizing.font(14),
                    weight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: textColor
                  ),
                ),
                if(isSelected) ...[
                  customSelected
                ]
              ],
            )
          ),
        );
      }).toList(),
    );
  }

  @protected
  Widget preference() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: PreferenceOption.values.map((preference) {
        bool isSelected = _preference.equals(preference);

        if(preference.isNone) {
          return Container();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: item(
            isSelected: isSelected,
            onTap: () => _refresh<PreferenceOption>(current: _preference, update: preference),
            child: Row(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextBuilder(
                    text: preference.type,
                    size: Sizing.font(14),
                    weight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: textColor
                  ),
                ),
                if(isSelected) ...[
                  const SizedBox(width: 20),
                  customSelected
                ]
              ],
            )
          ),
        );
      }).toList(),
    );
  }

  @protected
  Widget schedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ScheduleTime.values.map((schedule) {
        bool isSelected = _schedule.equals(schedule);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: item(
            isSelected: isSelected,
            onTap: () => _refresh<ScheduleTime>(current: _schedule, update: schedule),
            child: Row(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextBuilder(
                    text: schedule.type,
                    size: Sizing.font(14),
                    weight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: textColor
                  ),
                ),
                if(isSelected) ...[
                  customSelected
                ]
              ],
            )
          ),
        );
      }).toList(),
    );
  }

  @protected
  Widget security() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: SecurityType.values.map((security) {
        bool isSelected = _security.equals(security);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: item(
            isSelected: isSelected,
            onTap: () => _refresh<SecurityType>(current: _security, update: security),
            child: Row(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextBuilder(
                    text: security.type,
                    size: Sizing.font(14),
                    weight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: textColor
                  ),
                ),
                if(isSelected) ...[
                  customSelected
                ]
              ],
            )
          ),
        );
      }).toList(),
    );
  }

  @protected
  Widget theme() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisExtent: 250
      ),
      itemCount: ThemeType.values.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final theme = ThemeType.values[index];
        bool isSelected = _theme.equals(theme);

        return item(
          isSelected: isSelected,
          onTap: () => _refresh<ThemeType>(current: _theme, update: theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    theme.isLight ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: Theme.of(context).primaryColor
                  ),
                  const SizedBox(width: 10),
                  TextBuilder(
                    text: theme.isLight ? "Light Theme" : "Dark Theme",
                    size: Sizing.font(16),
                    weight: FontWeight.bold,
                    color: textColor
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Image.asset(
                  theme.isLight ? SmartThemeAssets.light : SmartThemeAssets.dark,
                  width: MediaQuery.sizeOf(context).width
                )
              ),
              const SizedBox(height: 10),
              TextBuilder(
                text: theme.type,
                size: Sizing.font(16),
                weight: FontWeight.bold,
                color: textColor
              ),
              TextBuilder(
                text: theme.isLight
                  ? "Active when you want something brighter"
                  : "Eye-friendly design for low-light environment",
                size: Sizing.font(14),
                color: textColor
              ),
            ],
          )
        );
      }
    );
  }

  Widget item({required bool isSelected, required Widget child, VoidCallback? onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: isSelected
          ? (widget.selectedItemColor ?? CommonColors.instance.green.lighten(45))
          : (widget.staleItemColor ?? CommonColors.instance.green),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: EdgeInsets.all(Sizing.space(16)), child: child),
        ),
      ),
    );
  }
}