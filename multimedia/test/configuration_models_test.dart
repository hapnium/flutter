import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimedia/multimedia.dart';

void main() {
  group('MultimediaDoneButtonConfiguration', () {
    test('creates instance with defaults', () {
      final config = MultimediaDoneButtonConfiguration();

      expect(config.widget, isNull);
      expect(config.text, isNull);
      expect(config.size, isNull);
      expect(config.fontWeight, isNull);
      expect(config.color, isNull);
      expect(config.backgroundColor, isNull);
      expect(config.foregroundColor, isNull);
      expect(config.overlayColor, isNull);
      expect(config.shape, isNull);
      expect(config.padding, isNull);
    });

    test('stores provided values', () {
      final config = MultimediaDoneButtonConfiguration(
        text: 'Done',
        size: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF000000),
        backgroundColor: const Color(0xFFFFFFFF),
        padding: const EdgeInsets.all(8),
      );

      expect(config.text, equals('Done'));
      expect(config.size, equals(16));
      expect(config.fontWeight, equals(FontWeight.bold));
      expect(config.color, isNotNull);
      expect(config.backgroundColor, isNotNull);
      expect(config.padding, isNotNull);
    });
  });

  group('MultimediaIconConfiguration', () {
    test('creates instance with defaults', () {
      final config = MultimediaIconConfiguration();

      expect(config.grid, isNull);
      expect(config.list, isNull);
      expect(config.color, isNull);
      expect(config.size, isNull);
    });

    test('stores provided values', () {
      final config = MultimediaIconConfiguration(
        grid: const IconData(0xe123),
        list: const IconData(0xe456),
        color: const Color(0xFF0000FF),
        size: 24,
      );

      expect(config.grid, isNotNull);
      expect(config.list, isNotNull);
      expect(config.color, isNotNull);
      expect(config.size, equals(24));
    });
  });

  group('MultimediaGridFilterConfiguration', () {
    test('creates instance with defaults', () {
      final config = MultimediaGridFilterConfiguration();

      expect(config.spacing, isNull);
      expect(config.runSpacing, isNull);
      expect(config.buttonPadding, isNull);
      expect(config.buttonShape, isNull);
      expect(config.buttonTextSize, isNull);
      expect(config.buttonColor, isNull);
      expect(config.padding, isNull);
      expect(config.runAlignment, isNull);
      expect(config.crossAlignment, isNull);
    });

    test('stores provided values', () {
      final config = MultimediaGridFilterConfiguration(
        spacing: 8,
        runSpacing: 4,
        buttonTextSize: 12,
        buttonColor: const Color(0xFF00FF00),
      );

      expect(config.spacing, equals(8));
      expect(config.runSpacing, equals(4));
      expect(config.buttonTextSize, equals(12));
      expect(config.buttonColor, isNotNull);
    });
  });

  group('MultimediaNoItemConfiguration', () {
    test('creates instance with defaults', () {
      final config = MultimediaNoItemConfiguration();

      expect(config.iconWidget, isNull);
      expect(config.message, isNull);
      expect(config.icon, isNull);
      expect(config.textColor, isNull);
      expect(config.iconSize, isNull);
      expect(config.textSize, isNull);
      expect(config.spacing, isNull);
      expect(config.opacity, isNull);
    });

    test('stores provided values', () {
      final config = MultimediaNoItemConfiguration(
        message: 'No items found',
        icon: const IconData(0xe789),
        iconSize: 48,
        textSize: 16,
        spacing: 12,
        opacity: 0.6,
      );

      expect(config.message, equals('No items found'));
      expect(config.icon, isNotNull);
      expect(config.iconSize, equals(48));
      expect(config.textSize, equals(16));
      expect(config.spacing, equals(12));
      expect(config.opacity, equals(0.6));
    });
  });

  group('MultimediaNoPermissionConfiguration', () {
    test('creates instance with defaults', () {
      final config = MultimediaNoPermissionConfiguration();

      expect(config.iconWidget, isNull);
      expect(config.textColor, isNull);
      expect(config.iconSize, isNull);
      expect(config.textSize, isNull);
      expect(config.spacing, isNull);
      expect(config.buttonColor, isNull);
      expect(config.buttonWeight, isNull);
      expect(config.buttonSize, isNull);
      expect(config.buttonPadding, isNull);
      expect(config.buttonShape, isNull);
      expect(config.buttonOverlayColor, isNull);
      expect(config.opacity, isNull);
      expect(config.buttonBackgroundColor, isNull);
      expect(config.buttonForegroundColor, isNull);
      expect(config.icon, isNull);
      expect(config.message, isNull);
      expect(config.buttonText, isNull);
    });

    test('stores provided values', () {
      final config = MultimediaNoPermissionConfiguration(
        message: 'Permission required',
        buttonText: 'Grant',
        icon: const IconData(0xeABC),
        iconSize: 40,
        buttonBackgroundColor: const Color(0xFFFF0000),
      );

      expect(config.message, equals('Permission required'));
      expect(config.buttonText, equals('Grant'));
      expect(config.icon, isNotNull);
      expect(config.iconSize, equals(40));
      expect(config.buttonBackgroundColor, isNotNull);
    });
  });

  group('MultimediaFileManagerConfiguration', () {
    test('creates instance with defaults', () {
      final config = MultimediaFileManagerConfiguration();

      expect(config.color, isNull);
      expect(config.text, isNull);
      expect(config.body, isNull);
      expect(config.onPressed, isNull);
      expect(config.icon, isNull);
      expect(config.onError, isNull);
    });

    test('stores provided values', () {
      bool pressed = false;
      final config = MultimediaFileManagerConfiguration(
        text: 'Browse',
        body: 'Select files',
        icon: const IconData(0xeDEF),
        onPressed: () => pressed = true,
      );

      expect(config.text, equals('Browse'));
      expect(config.body, equals('Select files'));
      expect(config.icon, isNotNull);
      expect(config.onPressed, isNotNull);

      config.onPressed!();
      expect(pressed, isTrue);
    });
  });

  group('MultimediaLayoutConfiguration', () {
    test('creates instance with default values', () {
      final config = MultimediaLayoutConfiguration();

      expect(config.floatingButton, isNull);
      expect(config.appbar, isNull);
      expect(config.bottomNavbar, isNull);
      expect(config.bottomSheet, isNull);
      expect(config.floater, isNull);
      expect(config.drawer, isNull);
      expect(config.endDrawer, isNull);
      expect(config.floatConfig, isNull);
      expect(config.loadingHeight, equals(1));
      expect(config.loadingPosition, equals(0));
      expect(config.loadingWidth, isNull);
      expect(config.floaterWidth, isNull);
      expect(config.backgroundColor, isNull);
      expect(config.darkBackgroundColor, isNull);
      expect(config.barColor, isNull);
      expect(config.navigationColor, isNull);
      expect(config.loadingColor, isNull);
      expect(config.loadingBackgroundColor, isNull);
      expect(config.floatingLocation, isNull);
      expect(config.needSafeArea, isTrue);
      expect(config.useFloaterWidth, isFalse);
      expect(config.withActivity, isFalse);
      expect(config.extendBody, isFalse);
      expect(config.extendBehindAppbar, isFalse);
      expect(config.goDark, isFalse);
      expect(config.shouldOverride, isFalse);
      expect(config.shouldWillPop, isTrue);
      expect(config.isLoading, isFalse);
      expect(config.floatFit, isNull);
      expect(config.loadingFit, isNull);
      expect(config.onInactivity, isNull);
      expect(config.onActivity, isNull);
      expect(config.inactivityDuration, isNull);
      expect(config.theme, isNull);
      expect(config.onWillPop, isNull);
      expect(config.config, isNull);
    });

    test('stores custom values', () {
      final config = MultimediaLayoutConfiguration(
        loadingHeight: 2,
        loadingPosition: 1,
        needSafeArea: false,
        useFloaterWidth: true,
        withActivity: true,
        extendBody: true,
        extendBehindAppbar: true,
        goDark: true,
        shouldOverride: true,
        shouldWillPop: false,
        isLoading: true,
        backgroundColor: const Color(0xFFFFFFFF),
      );

      expect(config.loadingHeight, equals(2));
      expect(config.loadingPosition, equals(1));
      expect(config.needSafeArea, isFalse);
      expect(config.useFloaterWidth, isTrue);
      expect(config.withActivity, isTrue);
      expect(config.extendBody, isTrue);
      expect(config.extendBehindAppbar, isTrue);
      expect(config.goDark, isTrue);
      expect(config.shouldOverride, isTrue);
      expect(config.shouldWillPop, isFalse);
      expect(config.isLoading, isTrue);
      expect(config.backgroundColor, isNotNull);
    });
  });

  group('MultimediaGalleryConfiguration', () {
    test('creates instance with default values', () {
      final config = MultimediaGalleryConfiguration();

      expect(config.title, isEmpty);
      expect(config.showOnlyVideo, isFalse);
      expect(config.showOnlyPhoto, isTrue);
      expect(config.allowMultipleSelection, isFalse);
      expect(config.maxSelection, isNull);
      expect(config.configuration, isNull);
      expect(config.iconConfiguration, isNull);
      expect(config.layoutConfiguration, isNull);
      expect(config.noItemConfiguration, isNull);
      expect(config.noPermissionConfiguration, isNull);
      expect(config.fileManagerConfiguration, isNull);
      expect(config.appBarElevation, isNull);
      expect(config.titleColor, isNull);
      expect(config.titleWeight, isNull);
      expect(config.titleSize, isNull);
      expect(config.titleWidget, isNull);
      expect(config.dividerColor, isNull);
      expect(config.dividerThickness, isNull);
      expect(config.showHeader, isTrue);
      expect(config.headerPadding, isNull);
      expect(config.headerColor, isNull);
      expect(config.headerSize, isNull);
      expect(config.headerWeight, isNull);
      expect(config.showDivider, isTrue);
      expect(config.showManager, isTrue);
      expect(config.emptyBuilder, isNull);
      expect(config.noPermissionBuilder, isNull);
      expect(config.spacing, isNull);
      expect(config.mainAxisAlignment, isNull);
      expect(config.mainAxisSize, isNull);
      expect(config.crossAxisAlignment, isNull);
      expect(config.onLayoutChanged, isNull);
      expect(config.hasPermission, isNull);
      expect(config.popAllWhileGoingBack, isTrue);
      expect(config.maxSize, isNull);
      expect(config.minSize, isNull);
      expect(config.loadingBuilder, isNull);
      expect(config.permissionCheckBuilder, isNull);
    });

    test('stores custom values', () {
      final config = MultimediaGalleryConfiguration(
        title: 'My Gallery',
        showOnlyVideo: true,
        showOnlyPhoto: false,
        allowMultipleSelection: true,
        maxSelection: 5,
        appBarElevation: 4.0,
        showHeader: false,
        showDivider: false,
        showManager: false,
        popAllWhileGoingBack: false,
        maxSize: 1024,
        minSize: 100,
      );

      expect(config.title, equals('My Gallery'));
      expect(config.showOnlyVideo, isTrue);
      expect(config.showOnlyPhoto, isFalse);
      expect(config.allowMultipleSelection, isTrue);
      expect(config.maxSelection, equals(5));
      expect(config.appBarElevation, equals(4.0));
      expect(config.showHeader, isFalse);
      expect(config.showDivider, isFalse);
      expect(config.showManager, isFalse);
      expect(config.popAllWhileGoingBack, isFalse);
      expect(config.maxSize, equals(1024));
      expect(config.minSize, equals(100));
    });
  });

  group('MultimediaGalleryAlbumConfiguration', () {
    test('creates instance with default values', () {
      final config = MultimediaGalleryAlbumConfiguration();

      expect(config.popAllWhileGoingBack, isTrue);
      expect(config.configuration, isNull);
      expect(config.iconConfiguration, isNull);
      expect(config.layoutConfiguration, isNull);
      expect(config.doneButtonConfiguration, isNull);
      expect(config.gridFilterConfiguration, isNull);
      expect(config.noItemConfiguration, isNull);
      expect(config.showFilters, isFalse);
      expect(config.grids, isNull);
      expect(config.titleWidget, isNull);
      expect(config.title, isNull);
      expect(config.titleSize, isNull);
      expect(config.titleWeight, isNull);
      expect(config.titleColor, isNull);
      expect(config.appBarElevation, isNull);
      expect(config.gridViewSpacing, isNull);
      expect(config.gridViewMainAlignment, isNull);
      expect(config.gridViewMainAxisSize, isNull);
      expect(config.gridViewCrossAlignment, isNull);
      expect(config.loadingBuilder, isNull);
      expect(config.emptyBuilder, isNull);
      expect(config.onGridChanged, isNull);
      expect(config.onLayoutChanged, isNull);
      expect(config.loadingColor, isNull);
      expect(config.maxSize, isNull);
      expect(config.minSize, isNull);
      expect(config.onErrorReceived, isNull);
      expect(config.onInfoReceived, isNull);
    });

    test('stores custom values', () {
      final config = MultimediaGalleryAlbumConfiguration(
        popAllWhileGoingBack: false,
        showFilters: true,
        grids: ['2x', '3x', '4x'],
        title: 'Album',
        titleSize: 18,
        appBarElevation: 2,
        maxSize: 5000,
        minSize: 50,
      );

      expect(config.popAllWhileGoingBack, isFalse);
      expect(config.showFilters, isTrue);
      expect(config.grids, equals(['2x', '3x', '4x']));
      expect(config.title, equals('Album'));
      expect(config.titleSize, equals(18));
      expect(config.appBarElevation, equals(2));
      expect(config.maxSize, equals(5000));
      expect(config.minSize, equals(50));
    });
  });

  group('MultimediaCameraConfiguration', () {
    test('creates instance with required onGoingBack', () {
      bool backPressed = false;
      final config = MultimediaCameraConfiguration(
        onGoingBack: () => backPressed = true,
      );

      expect(config.onGoingBack, isNotNull);
      expect(config.showOnlyVideo, isFalse);
      expect(config.showOnlyPhoto, isTrue);
      expect(config.isWeb, isFalse);
      expect(config.cameras, isEmpty);
      expect(config.info, isEmpty);
      expect(config.maxDuration, equals(30));
      expect(config.minDuration, equals(1));

      config.onGoingBack();
      expect(backPressed, isTrue);
    });

    test('stores custom values', () {
      final config = MultimediaCameraConfiguration(
        onGoingBack: () {},
        showOnlyVideo: true,
        showOnlyPhoto: false,
        isWeb: true,
        info: 'Camera info',
        maxDuration: 60,
        minDuration: 5,
        activeColor: const Color(0xFF00FF00),
        recordingColor: const Color(0xFFFF0000),
      );

      expect(config.showOnlyVideo, isTrue);
      expect(config.showOnlyPhoto, isFalse);
      expect(config.isWeb, isTrue);
      expect(config.info, equals('Camera info'));
      expect(config.maxDuration, equals(60));
      expect(config.minDuration, equals(5));
      expect(config.activeColor, isNotNull);
      expect(config.recordingColor, isNotNull);
    });

    test('assertion fails when maxDuration equals minDuration', () {
      expect(
        () => MultimediaCameraConfiguration(
          onGoingBack: () {},
          maxDuration: 10,
          minDuration: 10,
        ),
        throwsAssertionError,
      );
    });

    test('assertion fails when maxDuration is less than minDuration', () {
      expect(
        () => MultimediaCameraConfiguration(
          onGoingBack: () {},
          maxDuration: 5,
          minDuration: 10,
        ),
        throwsAssertionError,
      );
    });
  });

  group('AlbumViewConfiguration', () {
    test('creates instance with all null defaults', () {
      final config = AlbumViewConfiguration();

      expect(config.width, isNull);
      expect(config.ratio, isNull);
      expect(config.mediumItemBuilder, isNull);
      expect(config.selectedIndicator, isNull);
      expect(config.scrollThickness, isNull);
      expect(config.padding, isNull);
      expect(config.separator, isNull);
      expect(config.itemHeight, isNull);
      expect(config.imageHeight, isNull);
      expect(config.imageWidth, isNull);
      expect(config.imageFit, isNull);
      expect(config.videoIcon, isNull);
      expect(config.imageIcon, isNull);
      expect(config.defaultIcon, isNull);
      expect(config.itemBorderRadius, isNull);
      expect(config.unselectedShape, isNull);
      expect(config.selectedShape, isNull);
      expect(config.itemSpacing, isNull);
      expect(config.itemMainAxisSize, isNull);
      expect(config.itemMainAxisAlignment, isNull);
      expect(config.itemCrossAxisAlignment, isNull);
      expect(config.itemWidth, isNull);
      expect(config.itemBackgroundColor, isNull);
      expect(config.textPadding, isNull);
      expect(config.textSpacing, isNull);
      expect(config.textMainAxisSize, isNull);
      expect(config.textMainAxisAlignment, isNull);
      expect(config.textCrossAxisAlignment, isNull);
      expect(config.titleSize, isNull);
      expect(config.titleWeight, isNull);
      expect(config.titleColor, isNull);
      expect(config.titleFlow, isNull);
      expect(config.fileSize, isNull);
      expect(config.fileSizeColor, isNull);
      expect(config.fileSizeSpacing, isNull);
      expect(config.fileSizeMainAxisSize, isNull);
      expect(config.fileSizeMainAxisAlignment, isNull);
      expect(config.fileSizeCrossAxisAlignment, isNull);
      expect(config.fileSizeFlow, isNull);
      expect(config.iconSize, isNull);
      expect(config.unselectedColor, isNull);
      expect(config.selectedColor, isNull);
      expect(config.mainAxisSpacing, isNull);
      expect(config.crossAxisSpacing, isNull);
      expect(config.showIcon, isTrue);
    });

    test('stores custom values', () {
      final config = AlbumViewConfiguration(
        width: 120,
        ratio: 1.0,
        imageFit: BoxFit.cover,
        itemSpacing: 8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        showIcon: false,
        titleSize: 14,
        iconSize: 20,
      );

      expect(config.width, equals(120));
      expect(config.ratio, equals(1.0));
      expect(config.imageFit, equals(BoxFit.cover));
      expect(config.itemSpacing, equals(8));
      expect(config.mainAxisSpacing, equals(10));
      expect(config.crossAxisSpacing, equals(10));
      expect(config.showIcon, isFalse);
      expect(config.titleSize, equals(14));
      expect(config.iconSize, equals(20));
    });
  });

  group('GalleryViewConfiguration', () {
    test('creates instance with defaults', () {
      final config = GalleryViewConfiguration();

      expect(config.maxSelection, isNull);
      expect(config.displayCount, isNull);
      expect(config.ratio, isNull);
      expect(config.width, isNull);
      expect(config.padding, isNull);
      expect(config.scrollThickness, isNull);
      expect(config.mainAxisSpacing, isNull);
      expect(config.crossAxisSpacing, isNull);
      expect(config.borderRadius, isNull);
      expect(config.imageFit, isNull);
      expect(config.imageBackgroundColor, isNull);
      expect(config.contentPadding, isNull);
      expect(config.contentSpacing, isNull);
      expect(config.contentMainAxisAlignment, isNull);
      expect(config.contentCrossAxisAlignment, isNull);
      expect(config.nameSize, isNull);
      expect(config.nameWeight, isNull);
      expect(config.nameColor, isNull);
      expect(config.nameOverflow, isNull);
      expect(config.countSize, isNull);
      expect(config.countColor, isNull);
      expect(config.countOverflow, isNull);
      expect(config.newestColor, isNull);
      expect(config.oldestColor, isNull);
      expect(config.infoColor, isNull);
      expect(config.infoSize, isNull);
      expect(config.infoPadding, isNull);
      expect(config.infoRadius, isNull);
      expect(config.albumItemBuilder, isNull);
      expect(config.route, isNull);
      expect(config.separator, isNull);
      expect(config.imageHeight, isNull);
      expect(config.imageWidth, isNull);
    });

    test('stores custom values', () {
      final config = GalleryViewConfiguration(
        maxSelection: 10,
        displayCount: 3,
        ratio: 0.8,
        width: 150,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        imageFit: BoxFit.cover,
        contentSpacing: 6,
        nameSize: 16,
        countSize: 12,
        route: '/albumDetails',
      );

      expect(config.maxSelection, equals(10));
      expect(config.displayCount, equals(3));
      expect(config.ratio, equals(0.8));
      expect(config.width, equals(150));
      expect(config.mainAxisSpacing, equals(8));
      expect(config.crossAxisSpacing, equals(8));
      expect(config.imageFit, equals(BoxFit.cover));
      expect(config.contentSpacing, equals(6));
      expect(config.nameSize, equals(16));
      expect(config.countSize, equals(12));
      expect(config.route, equals('/albumDetails'));
    });
  });
}