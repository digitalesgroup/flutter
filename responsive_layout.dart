// lib/widgets/responsive_layout.dart

import 'package:flutter/material.dart';

/// Clase de utilidad que proporciona breakpoints y métodos para determinar
/// el tipo de dispositivo según el tamaño de pantalla.
class ResponsiveBreakpoints {
  // Breakpoints
  static const double mobileBreakpoint = 650;
  static const double tabletBreakpoint = 1100;

  /// Comprueba si el ancho de pantalla corresponde a un móvil
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Comprueba si el ancho de pantalla corresponde a una tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  /// Comprueba si el ancho de pantalla corresponde a un escritorio
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Obtiene el número de columnas para un grid basado en el ancho de pantalla
  static int getColumnCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 1; // Móvil: 1 columna
    } else if (width < tabletBreakpoint) {
      return 2; // Tablet: 2 columnas
    } else if (width < 1400) {
      return 3; // Desktop pequeño: 3 columnas
    } else {
      return 4; // Desktop grande: 4 columnas
    }
  }

  /// Obtiene un factor de escala para ajustar tamaños de widgets
  static double getScaleFactor(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 1.0;
    } else if (width < tabletBreakpoint) {
      return 1.1;
    } else {
      return 1.2;
    }
  }
}

/// Widget responsivo que muestra diferentes layouts según el tamaño de pantalla.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;

  const ResponsiveLayout({
    Key? key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tabletBreakpoint) {
          // Mostrar layout de escritorio si está disponible, sino usar tablet o móvil
          return desktopLayout ?? tabletLayout ?? mobileLayout;
        } else if (constraints.maxWidth >=
            ResponsiveBreakpoints.mobileBreakpoint) {
          // Mostrar layout de tablet si está disponible, sino usar móvil
          return tabletLayout ?? mobileLayout;
        } else {
          // Siempre mostrar layout de móvil para pantallas pequeñas
          return mobileLayout;
        }
      },
    );
  }
}

/// Widget responsivo para una fila que se convierte en columna en móvil.
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment rowMainAxisAlignment;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final MainAxisAlignment columnMainAxisAlignment;
  final CrossAxisAlignment columnCrossAxisAlignment;
  final MainAxisSize rowMainAxisSize;
  final MainAxisSize columnMainAxisSize;
  final double spacing;

  const ResponsiveRowColumn({
    Key? key,
    required this.children,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
    this.columnMainAxisAlignment = MainAxisAlignment.start,
    this.columnCrossAxisAlignment = CrossAxisAlignment.center,
    this.rowMainAxisSize = MainAxisSize.max,
    this.columnMainAxisSize = MainAxisSize.max,
    this.spacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.isMobile(context)) {
      // En móvil, mostrar como columna
      return Column(
        mainAxisAlignment: columnMainAxisAlignment,
        crossAxisAlignment: columnCrossAxisAlignment,
        mainAxisSize: columnMainAxisSize,
        children: _addSpacingColumn(),
      );
    } else {
      // En tablet/desktop, mostrar como fila
      return Row(
        mainAxisAlignment: rowMainAxisAlignment,
        crossAxisAlignment: rowCrossAxisAlignment,
        mainAxisSize: rowMainAxisSize,
        children: _addSpacingRow(),
      );
    }
  }

  List<Widget> _addSpacingRow() {
    List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(width: spacing));
      }
    }
    return spacedChildren;
  }

  List<Widget> _addSpacingColumn() {
    List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(height: spacing));
      }
    }
    return spacedChildren;
  }
}

/// Widget para manejar tamaños de fuente responsivos
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double mobileFontSize;
  final double tabletFontSize;
  final double desktopFontSize;

  const ResponsiveText({
    Key? key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    required this.mobileFontSize,
    required this.tabletFontSize,
    required this.desktopFontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double fontSize;

    if (ResponsiveBreakpoints.isDesktop(context)) {
      fontSize = desktopFontSize;
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      fontSize = tabletFontSize;
    } else {
      fontSize = mobileFontSize;
    }

    return Text(
      text,
      style:
          style?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Widget para mostrar/ocultar elementos según el dispositivo
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;
  final Widget? replacement;

  const ResponsiveVisibility({
    Key? key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.replacement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isVisible = false;

    if (ResponsiveBreakpoints.isMobile(context)) {
      isVisible = visibleOnMobile;
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      isVisible = visibleOnTablet;
    } else if (ResponsiveBreakpoints.isDesktop(context)) {
      isVisible = visibleOnDesktop;
    }

    if (isVisible) {
      return child;
    } else {
      return replacement ?? SizedBox.shrink();
    }
  }
}

/// Widget para crear un grid responsivo
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGridView({
    Key? key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final columnCount = ResponsiveBreakpoints.getColumnCount(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
