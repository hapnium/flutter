import 'package:flutter_test/flutter_test.dart';
import 'package:smart/smart.dart';

void main() {
  group('PageableStatusExtension', () {
    test('loading getters match their status', () {
      expect(PageableStatus.LOADING_FIRST_PAGE.isLoadingFirstPage, isTrue);
      expect(PageableStatus.LOADING_NEW_PAGE.isLoadingMore, isTrue);
      expect(PageableStatus.LOADING_PREVIOUS_PAGE.isLoadingPreviousPage, isTrue);
      expect(PageableStatus.REFRESHING.isRefreshing, isTrue);

      expect(PageableStatus.LOADED_PAGE.isLoadingFirstPage, isFalse);
      expect(PageableStatus.LOADED_PAGE.isLoadingMore, isFalse);
      expect(PageableStatus.LOADED_PAGE.isLoadingPreviousPage, isFalse);
      expect(PageableStatus.LOADED_PAGE.isRefreshing, isFalse);
    });

    test('isLoading covers every in-flight status', () {
      expect(PageableStatus.LOADING_FIRST_PAGE.isLoading, isTrue);
      expect(PageableStatus.LOADING_NEW_PAGE.isLoading, isTrue);
      expect(PageableStatus.LOADING_PREVIOUS_PAGE.isLoading, isTrue);
      expect(PageableStatus.REFRESHING.isLoading, isTrue);

      for (final status in [
        PageableStatus.LOADED_PAGE,
        PageableStatus.NO_ITEMS_FOUND,
        PageableStatus.FIRST_PAGE_ERROR,
        PageableStatus.NEW_PAGE_ERROR,
        PageableStatus.PREVIOUS_PAGE_ERROR,
        PageableStatus.COMPLETED,
      ]) {
        expect(status.isLoading, isFalse, reason: '$status');
      }
    });

    test('isLoaded covers loaded and completed', () {
      expect(PageableStatus.LOADED_PAGE.isLoaded, isTrue);
      expect(PageableStatus.COMPLETED.isLoaded, isTrue);
      expect(PageableStatus.LOADING_NEW_PAGE.isLoaded, isFalse);
      expect(PageableStatus.NO_ITEMS_FOUND.isLoaded, isFalse);
    });

    test('terminal state getters', () {
      expect(PageableStatus.NO_ITEMS_FOUND.isNoItemsFound, isTrue);
      expect(PageableStatus.FIRST_PAGE_ERROR.isFirstPageError, isTrue);
      expect(PageableStatus.NEW_PAGE_ERROR.isLoadingMoreError, isTrue);
      expect(PageableStatus.PREVIOUS_PAGE_ERROR.isPreviousPageError, isTrue);
      expect(PageableStatus.COMPLETED.isCompleted, isTrue);

      expect(PageableStatus.LOADED_PAGE.isNoItemsFound, isFalse);
      expect(PageableStatus.LOADED_PAGE.isFirstPageError, isFalse);
      expect(PageableStatus.LOADED_PAGE.isLoadingMoreError, isFalse);
      expect(PageableStatus.LOADED_PAGE.isPreviousPageError, isFalse);
      expect(PageableStatus.LOADED_PAGE.isCompleted, isFalse);
    });

    test('hasData is true whenever items are on screen', () {
      for (final status in [
        PageableStatus.LOADED_PAGE,
        PageableStatus.LOADING_NEW_PAGE,
        PageableStatus.LOADING_PREVIOUS_PAGE,
        PageableStatus.NEW_PAGE_ERROR,
        PageableStatus.PREVIOUS_PAGE_ERROR,
        PageableStatus.COMPLETED,
      ]) {
        expect(status.hasData, isTrue, reason: '$status');
      }

      for (final status in [
        PageableStatus.LOADING_FIRST_PAGE,
        PageableStatus.NO_ITEMS_FOUND,
        PageableStatus.FIRST_PAGE_ERROR,
        PageableStatus.REFRESHING,
      ]) {
        expect(status.hasData, isFalse, reason: '$status');
      }
    });

    test('hasError covers all three error statuses', () {
      for (final status in [
        PageableStatus.FIRST_PAGE_ERROR,
        PageableStatus.NEW_PAGE_ERROR,
        PageableStatus.PREVIOUS_PAGE_ERROR,
      ]) {
        expect(status.hasError, isTrue, reason: '$status');
      }

      for (final status in [
        PageableStatus.LOADING_FIRST_PAGE,
        PageableStatus.LOADED_PAGE,
        PageableStatus.LOADING_NEW_PAGE,
        PageableStatus.LOADING_PREVIOUS_PAGE,
        PageableStatus.NO_ITEMS_FOUND,
        PageableStatus.COMPLETED,
        PageableStatus.REFRESHING,
      ]) {
        expect(status.hasError, isFalse, reason: '$status');
      }
    });

    test('canLoadMore excludes loading and empty states', () {
      expect(PageableStatus.LOADED_PAGE.canLoadMore, isTrue);
      expect(PageableStatus.NEW_PAGE_ERROR.canLoadMore, isTrue);
      // COMPLETED is status-level loadable; PageableView gates it on the
      // next-page cursor via hasNextPage.
      expect(PageableStatus.COMPLETED.canLoadMore, isTrue);

      for (final status in [
        PageableStatus.LOADING_FIRST_PAGE,
        PageableStatus.LOADING_NEW_PAGE,
        PageableStatus.LOADING_PREVIOUS_PAGE,
        PageableStatus.NO_ITEMS_FOUND,
        PageableStatus.FIRST_PAGE_ERROR,
        PageableStatus.PREVIOUS_PAGE_ERROR,
        PageableStatus.REFRESHING,
      ]) {
        expect(status.canLoadMore, isFalse, reason: '$status');
      }
    });

    test('canLoadPrevious excludes first-page loading', () {
      expect(PageableStatus.LOADED_PAGE.canLoadPrevious, isTrue);
      expect(PageableStatus.NEW_PAGE_ERROR.canLoadPrevious, isTrue);
      expect(PageableStatus.PREVIOUS_PAGE_ERROR.canLoadPrevious, isTrue);
      // COMPLETED is status-level loadable; PageableView gates it on the
      // previous-page cursor via hasPreviousPage.
      expect(PageableStatus.COMPLETED.canLoadPrevious, isTrue);

      for (final status in [
        PageableStatus.LOADING_FIRST_PAGE,
        PageableStatus.LOADING_NEW_PAGE,
        PageableStatus.LOADING_PREVIOUS_PAGE,
        PageableStatus.NO_ITEMS_FOUND,
        PageableStatus.FIRST_PAGE_ERROR,
        PageableStatus.REFRESHING,
      ]) {
        expect(status.canLoadPrevious, isFalse, reason: '$status');
      }
    });
  });
}
