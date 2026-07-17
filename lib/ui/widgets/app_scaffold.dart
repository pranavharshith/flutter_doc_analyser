import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/utils/theme.dart';

/// Standard student/admin chrome: gradient body + gradient app bar.
///
/// Always paints under a proper [AppBar] (status bar safe). Prefer this over
/// custom `Container` app bars with `SafeArea(top: false)`.
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool showBackButton;
  final bool centerTitle;
  final VoidCallback? onBack;
  final bool useGradientBody;
  final PreferredSizeWidget? appBar;
  final bool showAppBar;
  final Key? scaffoldKey;
  final Widget? leading;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.showBackButton = true,
    this.centerTitle = true,
    this.onBack,
    this.useGradientBody = true,
    this.appBar,
    this.showAppBar = true,
    this.scaffoldKey,
    this.leading,
    this.backgroundColor,
  });

  /// Gradient app bar used across the student shell and secondary pages.
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
    bool centerTitle = true,
    VoidCallback? onBack,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.bgLight,
          fontSize: 18,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppTheme.appBarGradient),
      ),
      automaticallyImplyLeading: automaticallyImplyLeading && leading == null,
      leading: leading ??
          (showBackButton && Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.bgLight),
                  tooltip: 'Back',
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                )
              : null),
      actions: actions,
      iconTheme: const IconThemeData(color: AppTheme.bgLight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = AppTheme.scaffoldGradient(isDark);

    final PreferredSizeWidget? bar = !showAppBar
        ? null
        : appBar ??
            (title != null
                ? buildAppBar(
                    context: context,
                    title: title!,
                    actions: actions,
                    showBackButton: showBackButton,
                    centerTitle: centerTitle,
                    onBack: onBack,
                    leading: leading,
                  )
                : null);

    return Scaffold(
      key: scaffoldKey,
      appBar: bar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor ??
          (useGradientBody ? Colors.transparent : null),
      body: useGradientBody
          ? Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
              ),
              child: body,
            )
          : body,
    );
  }
}

/// Body-only gradient wrapper for tab pages that already sit under a parent
/// [AppScaffold] / shell app bar.
class AppGradientBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppGradientBody({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.scaffoldGradient(isDark),
        ),
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
  }
}
