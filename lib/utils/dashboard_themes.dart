enum DashboardLayoutTheme {
  multiCard, // Theme 1: Multiple cards layout
  comprehensive, // Theme 2: Single comprehensive card
  grid, // Theme 3: Grid layout
}

class DashboardThemeHelper {
  static const String dashboardThemeKey = 'dashboard_layout_theme';

  static String getThemeName(DashboardLayoutTheme theme) {
    switch (theme) {
      case DashboardLayoutTheme.multiCard:
        return 'Multi-Card Layout';
      case DashboardLayoutTheme.comprehensive:
        return 'Comprehensive View';
      case DashboardLayoutTheme.grid:
        return 'Grid Layout';
    }
  }

  static String getThemeDescription(DashboardLayoutTheme theme) {
    switch (theme) {
      case DashboardLayoutTheme.multiCard:
        return 'Detailed cards with spacious layout';
      case DashboardLayoutTheme.comprehensive:
        return 'Compact all-in-one view';
      case DashboardLayoutTheme.grid:
        return 'Balanced grid-based layout';
    }
  }
}
