import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Scaffold centré et borné en largeur, utilisé par tous les écrans d'auth
/// (login, étapes d'inscription, splash) pour rester lisibles et cohérents
/// aussi bien sur téléphone étroit que sur tablette/desktop.
class AuthScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool scrollable;

  const AuthScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kAuthMaxWidth),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: scrollable ? SingleChildScrollView(child: content) : content,
        ),
      ),
    );
  }
}
