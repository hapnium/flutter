import 'package:flutter/material.dart';
import 'package:hapnium/hapnium.dart';
import 'package:smart/src/assets/styled_social_assets.dart';
import 'package:smart/src/styles/colors/common_colors.dart';

import '../../export.dart';

const SmartShareConfig _defaultConfig = SmartShareConfig();

const SmartShareItemConfig _defaultItemConfig = SmartShareItemConfig();

/// {@template smart_share}
/// A widget that provides a customizable share sheet with various sharing options.
///
/// [SmartShare] allows users to easily share content via different social media
/// platforms and other sharing methods. It supports both list and grid layouts,
/// customizable item configurations, and loading states.
/// 
/// {@endtemplate}
class SmartShare extends StatelessWidget {
  /// A builder function to customize the appearance of each share item.
  final SmartShareItemBuilder? itemBuilder;

  /// A builder function to customize the list of share items.
  ///
  /// This can be used to configure the default list of share items. If [items] is provided, this is ignored.
  final SmartShareListItemBuilder? listBuilder;

  /// A list of share items to be displayed.
  final List<SmartShareItem>? items;

  /// A function to apply global configurations to each share item.
  final SmartShareItemConfigurer? globalConfiguration;

  /// A callback function that is triggered when a share item is clicked.
  final SmartShareItemCallback? onItemClicked;

  /// Configuration for the SmartShare widget, defining which sharing options are enabled.
  final SmartShareConfig config;

  /// Determines whether to use a grid layout.
  final Boolean _useGrid;

  /// The height of the SmartShare widget when using a grid layout.
  final Double? height;

  /// The spacing between share items when using a list layout.
  final Double? spacing;

  /// Indicates whether the SmartShare widget is in a loading state.
  final Boolean isLoading;

  /// Indicates whether the SmartShare widget is in dark mode.
  final Boolean isDarkMode;

  /// The size of the loading indicator.
  final Double? loadingSize;

  /// The grid delegate for customizing the layout of the grid.
  final SliverGridDelegate? gridDelegate;

  /// The scroll physics for the grid or list.
  final ScrollPhysics? physics;

  /// The padding around the grid or list.
  final EdgeInsetsGeometry? padding;

  /// Determines whether the grid or list should shrink-wrap its content.
  final Boolean shrinkWrap;

  /// The direction in which the grid or list should scroll.
  final Axis scrollDirection;

  /// The decoration to paint behind the [child].
  ///
  /// Use the [color] property to specify a simple solid color.
  ///
  /// The [child] is not clipped to the decoration. To clip a child to the shape
  /// of a particular [ShapeDecoration], consider using a [ClipPath] widget.
  final Decoration? loadingDecoration;

  /// Creates a SmartShare widget with a list layout.
  /// 
  /// {@macro smart_share}
  const SmartShare.list({
    super.key,
    this.isLoading = false,
    this.itemBuilder,
    this.globalConfiguration,
    this.onItemClicked,
    this.spacing,
    this.config = _defaultConfig,
    this.isDarkMode = false,
    this.loadingSize,
    this.items,
    this.listBuilder,
    this.loadingDecoration
  })  : _useGrid = false,
      gridDelegate = null,
      physics = null,
      padding = null,
      shrinkWrap = false,
      scrollDirection = Axis.horizontal,
      height = null;

  /// Creates a SmartShare widget with a grid layout.
  /// 
  /// {@macro smart_share}
  const SmartShare.grid({
    super.key,
    this.gridDelegate,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.horizontal,
    this.height = 180,
    this.isLoading = false,
    this.itemBuilder,
    this.globalConfiguration,
    this.onItemClicked,
    this.config = _defaultConfig,
    this.isDarkMode = false,
    this.loadingSize,
    this.spacing,
    this.items,
    this.listBuilder,
    this.loadingDecoration
  })  : _useGrid = true;

  @override
  Widget build(BuildContext context) {
    double spacer = spacing ?? 10;

    List<SmartShareItem> defaultItems = [
      if(config.enableCopyLink) ...[
        SmartShareItem(
          index: 0,
          icon: Icons.copy,
          label: "Copy",
          config: _defaultItemConfig
        )
      ],
      if(config.enableFacebook) ...[
        SmartShareItem(
          index: 1,
          asset: SmartStyledSocialAssets.facebook,
          label: "Facebook",
          config: _defaultItemConfig.copyWith(backgroundColor: CommonColors.instance.facebook),
          url: "https://www.facebook.com/sharer/sharer.php?u="
        )
      ],
      if(config.enableInstagram) ...[
        SmartShareItem(
          index: 2,
          asset: SmartStyledSocialAssets.instagram,
          label: "Instagram",
          config: _defaultItemConfig.copyWith(backgroundColor: CommonColors.instance.instagram),
          url: "https://www.instagram.com/create/caption/?caption="
        )
      ],
      if(config.enableSnapchat) ...[
        SmartShareItem(
          index: 3,
          asset: SmartStyledSocialAssets.snapchat,
          label: "Snapchat",
          config: _defaultItemConfig.copyWith(backgroundColor: CommonColors.instance.snapchat),
          url: 'snapchat://camera?caption='
        )
      ],
      if(config.enableTwitter) ...[
        SmartShareItem(
          index: 4,
          asset: SmartStyledSocialAssets.twitter,
          label: "Twitter",
          config: _defaultItemConfig.copyWith(backgroundColor: CommonColors.instance.twitterBlue),
          url: 'https://twitter.com/intent/tweet?text='
        )
      ],
      if(config.enableWhatsApp) ...[
        SmartShareItem(
          index: 5,
          asset: SmartStyledSocialAssets.whatsapp,
          label: "WhatsApp",
          config: _defaultItemConfig.copyWith(backgroundColor: CommonColors.instance.whatsapp),
          url: "https://api.whatsapp.com/send?text="
        )
      ],
      if(config.enableMoreOptions) ...[
        SmartShareItem(
          index: 6,
          icon: Icons.more_vert_rounded,
          label: "More",
          config: _defaultItemConfig
        )
      ]
    ];

    Widget builder(BuildContext context, ItemMetadata<SmartShareItem> meta) {
      SmartShareItemConfig configurer(SmartShareItemConfig config, int index) {
        return globalConfiguration.isNotNull ? globalConfiguration!(config, index) : config;
      }

      SmartShareItem item = meta.item;
      SmartShareItemConfig itemConfig = configurer(meta.item.config ?? _defaultItemConfig, meta.index);
      EdgeInsetsGeometry? padding = itemConfig.itemPadding ?? EdgeInsets.all(8);
      BorderRadiusGeometry itemBorderRadius = itemConfig.itemBorderRadius ?? BorderRadius.circular(50);

      Widget child() {
        if(item.icon.isNotNull) {
          return Icon(
            item.icon,
            size: itemConfig.itemSize,
            color: itemConfig.color ?? Theme.of(context).scaffoldBackgroundColor
          );
        } else {
          return Image.asset(
            item.asset,
            width: itemConfig.itemSize ?? MediaQuery.sizeOf(context).width,
            height: itemConfig.itemSize
          );
        }
      }

      String getShareMessage() {
        if (item.url.isEmpty) return "${config.message}\n\n${config.data}";

        String formattedMessage = config.linkFirst && config.addSpacingBetweenContent
            ? "${config.data}\n\n${config.message}"
            : config.linkFirst.isFalse && config.addSpacingBetweenContent
            ? "${config.message}\n\n${config.data}"
            : config.linkFirst
            ? "${config.data}${config.message}"
            : "${config.message}${config.data}";

        return "${item.url}${Uri.encodeComponent(formattedMessage)}";
      }

      return itemBuilder.isNotNull ? itemBuilder!(context, meta) : ClipRRect(
        borderRadius: itemConfig.borderRadius ?? BorderRadius.zero,
        child: Material(
          color: itemConfig.tapColor ?? Colors.transparent,
          child: InkWell(
            onTap: onItemClicked.isNotNull ? () => onItemClicked!(meta.item, getShareMessage()) : null,
            child: Padding(
              padding: itemConfig.padding ?? const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  spacing: spacer,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: itemBorderRadius,
                      child: Container(
                        padding: padding,
                        height: itemConfig.height ?? 40,
                        width: itemConfig.width ?? 40,
                        decoration: BoxDecoration(
                          color: itemConfig.gradient.isNotNull && itemConfig.useGradient ? null : itemConfig.backgroundColor,
                          gradient: itemConfig.gradient.isNotNull && itemConfig.useGradient ? itemConfig.gradient : null,
                          borderRadius: itemBorderRadius,
                        ),
                        child: child(),
                      ),
                    ),
                    if(itemConfig.showLabel) ...[
                      TextBuilder(
                        text: item.label,
                        color: itemConfig.textColor ?? Theme.of(context).primaryColor,
                        size: itemConfig.textSize ?? 12,
                        weight: itemConfig.textWeight,
                      )
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<SmartShareItem> items = this.items.isNotNull ? this.items! : listBuilder.isNotNull ? listBuilder!(defaultItems) : defaultItems;
    int listCount = isLoading ? 10 : items.length;

    if(_useGrid) {
      return SizedBox(
        height: height ?? 180,
        width: MediaQuery.sizeOf(context).width,
        child: GridView.builder(
          itemCount: listCount,
          gridDelegate: gridDelegate ?? SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: spacer,
            mainAxisSpacing: spacer,
            childAspectRatio: 1.2
          ),
          shrinkWrap: shrinkWrap,
          scrollDirection: scrollDirection,
          physics: physics ?? const NeverScrollableScrollPhysics(),
          padding: padding ?? const EdgeInsets.all(10),
          itemBuilder: (BuildContext context, int index) {
            if(isLoading) {
              return loading();
            } else {
              ItemMetadata<SmartShareItem> metadata = ItemMetadata(
                isFirst: index.equals(0),
                isLast: index.equals(items.length - 1),
                index: index,
                totalItems: items.length,
                item: items[index],
              );

              return builder(context, metadata);
            }
          }
        ),
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: scrollDirection,
        child: Row(
          spacing: spacer,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: listCount.listGenerator.map((int index) {
            if(isLoading) {
              return loading();
            } else {
              ItemMetadata<SmartShareItem> metadata = ItemMetadata(
                isFirst: index.equals(0),
                isLast: index.equals(items.length - 1),
                index: index,
                totalItems: items.length,
                item: items[index],
              );

              return builder(context, metadata);
            }
          }).toList(),
        )
      );
    }
  }

  Widget loading() {
    double loadSize = loadingSize ?? 50;

    return LoadingShimmer(
      isDarkMode: isDarkMode,
      content: Container(
        width: loadSize,
        height: loadSize,
        decoration: loadingDecoration ?? BoxDecoration(
          color: CommonColors.instance.shimmerHigh,
          shape: BoxShape.circle
        ),
      ),
    );
  }
}