import 'package:flutter/material.dart';

import '../../theme/dimens.dart';

abstract final class UCSpacingStyle {
  static const EdgeInsetsGeometry paddingWithAppBarHeight = EdgeInsets.only(
    top: Dimens.appBarHeight,
    left: Dimens.defaultSpace,
    right: Dimens.defaultSpace,
    bottom: Dimens.defaultSpace,
  );
}
