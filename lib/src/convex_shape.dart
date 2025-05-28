/*
 *  Copyright 2020 Chaobin Wu <chaobinwu89@gmail.com>
 *  
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *      http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'dart:math' as math;

/// A convex shape which implemented [NotchedShape].
///
/// It's used to draw a convex shape for [ConvexAppBar], If you are interested about
/// the math calculation, please refer to [CircularNotchedRectangle], it's based
/// on Bezier curve;
///
/// See also:
///
///  * [CircularNotchedRectangle], a rectangle with a smooth circular notch.
class ConvexNotchedRectangle extends NotchedShape {
  /// Draw the background with topLeft and topRight corner
  final double radius;

  /// Custom Mountain Notch
  final bool enableCustomMountainNotch;

  /// Create Shape instance
  const ConvexNotchedRectangle(
      {this.radius = 0, this.enableCustomMountainNotch = false});

  @override
  Path getOuterPath(Rect host, Rect? guest,
      {double smoothness = 0.2, double radius = 0.0}) {
    if (enableCustomMountainNotch) {
      if (guest == null || !host.overlaps(guest)) return Path()..addRect(host);

      final notchCenter = guest.center.dx;
      final notchWidth = guest.width * 1.5;
      final notchHeight = guest.height * 0.55;

      final leftNotch = notchCenter - notchWidth / 2;
      final rightNotch = notchCenter + notchWidth / 2;
      final peakHeight = host.top - notchHeight;

      final path = Path();

      // Start with top-left corner
      if (radius > 0) {
        path.moveTo(host.left, host.top + radius);
        path.arcToPoint(
          Offset(host.left + radius, host.top),
          radius: Radius.circular(radius),
          clockwise: false,
        );
      } else {
        path.moveTo(host.left, host.top);
      }

      // Line to left of notch
      path.lineTo(leftNotch, host.top);

      // Smooth left curve up to peak
      path.cubicTo(
        leftNotch + notchWidth * smoothness, host.top, // Control point 1
        notchCenter - notchWidth * smoothness, peakHeight, // Control point 2
        notchCenter, peakHeight, // Peak
      );

      // Smooth right curve down
      path.cubicTo(
        notchCenter + notchWidth * smoothness, peakHeight, // Control point 3
        rightNotch - notchWidth * smoothness, host.top, // Control point 4
        rightNotch, host.top,
      );

      // Top-right corner
      if (radius > 0) {
        path.lineTo(host.right - radius, host.top);
        path.arcToPoint(
          Offset(host.right, host.top + radius),
          radius: Radius.circular(radius),
          clockwise: false,
        );
      } else {
        path.lineTo(host.right, host.top);
      }

      // Remaining rectangle
      path.lineTo(host.right, host.bottom);
      path.lineTo(host.left, host.bottom);
      path.close();

      return path;
    } else {
      if (guest == null || !host.overlaps(guest)) return Path()..addRect(host);

      // The guest's shape is a circle bounded by the guest rectangle.
      // So the guest's radius is half the guest width.
      final notchRadius = guest.width / 2.0;

      const s1 = 15.0;
      const s2 = 1.0;

      final r = notchRadius;
      final a = -1.0 * r - s2;
      final b = host.top - guest.center.dy;

      final n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
      final p2xA = ((a * r * r) - n2) / (a * a + b * b);
      final p2xB = ((a * r * r) + n2) / (a * a + b * b);
      final p2yA = -math.sqrt(r * r - p2xA * p2xA);
      final p2yB = -math.sqrt(r * r - p2xB * p2xB);

      final p = List<Offset>.filled(6, Offset.zero, growable: false);
      // p0, p1, and p2 are the control points for segment A.
      p[0] = Offset(a - s1, b);
      p[1] = Offset(a, b);
      final cmp = b < 0 ? -1.0 : 1.0;
      p[2] = cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);

      // p3, p4, and p5 are the control points for segment B, which is a mirror
      // of segment A around the y axis.
      p[3] = Offset(-1.0 * p[2].dx, p[2].dy);
      p[4] = Offset(-1.0 * p[1].dx, p[1].dy);
      p[5] = Offset(-1.0 * p[0].dx, p[0].dy);

      // translate all points back to the absolute coordinate system.
      for (var i = 0; i < p.length; i += 1) {
        p[i] = p[i] + guest.center;
        //p[i] += padding;
      }

      return radius > 0
          ? (Path()
        ..moveTo(host.left, host.top + radius)
        ..arcToPoint(Offset(host.left + radius, host.top),
            radius: Radius.circular(radius))
        ..lineTo(p[0].dx, p[0].dy)
        ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
        ..arcToPoint(
          p[3],
          radius: Radius.circular(notchRadius),
          clockwise: true,
        )
        ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
        ..lineTo(host.right - radius, host.top)
        ..arcToPoint(Offset(host.right, host.top + radius),
            radius: Radius.circular(radius))
        ..lineTo(host.right, host.bottom)
        ..lineTo(host.left, host.bottom)
        ..close())
          : (Path()
        ..moveTo(host.left, host.top)
        ..lineTo(p[0].dx, p[0].dy)
        ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
        ..arcToPoint(
          p[3],
          radius: Radius.circular(notchRadius),
          clockwise: true,
        )
        ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
        ..lineTo(host.right, host.top)
        ..lineTo(host.right, host.bottom)
        ..lineTo(host.left, host.bottom)
        ..close());
    }
  }

// TODO : V1
// @override
// Path getOuterPath(Rect host, Rect? guest) {
//   if (guest == null || !host.overlaps(guest)) return Path()..addRect(host);
//
//   final notchCenter = guest.center.dx;
//   final notchWidth = guest.width * 2.0;
//   final notchHeight = guest.height * 0.7;
//
//   final leftNotch = notchCenter - notchWidth / 2;
//   final rightNotch = notchCenter + notchWidth / 2;
//   final peakHeight = host.top - notchHeight;
//
//   final path = Path();
//
//   // Start with top-left corner
//   if (radius > 0) {
//     path.moveTo(host.left, host.top + radius);
//     path.arcToPoint(
//       Offset(host.left + radius, host.top),
//       radius: Radius.circular(radius),
//       clockwise: false,
//     );
//   } else {
//     path.moveTo(host.left, host.top);
//   }
//
//   // Draw straight to start of left curve
//   path.lineTo(leftNotch, host.top);
//
//   // Smooth left curve up to peak using cubic Bezier
//   path.cubicTo(
//     leftNotch + notchWidth * 0.15, host.top,             // control point 1
//     notchCenter - notchWidth * 0.15, peakHeight,          // control point 2
//     notchCenter, peakHeight,                              // peak
//   );
//
//   // Smooth right curve down
//   path.cubicTo(
//     notchCenter + notchWidth * 0.15, peakHeight,          // control point 3
//     rightNotch - notchWidth * 0.15, host.top,             // control point 4
//     rightNotch, host.top,
//   );
//
//   // Continue to top-right
//   if (radius > 0) {
//     path.lineTo(host.right - radius, host.top);
//     path.arcToPoint(
//       Offset(host.right, host.top + radius),
//       radius: Radius.circular(radius),
//       clockwise: false,
//     );
//   } else {
//     path.lineTo(host.right, host.top);
//   }
//
//   // Finish rest of the shape
//   path.lineTo(host.right, host.bottom);
//   path.lineTo(host.left, host.bottom);
//   path.close();
//
//   return path;
// }
//
// TODO : V2
// @override
// Path getOuterPath(Rect host, Rect? guest, {double smoothness = 0.2, double radius = 0.0}) {
//   if (guest == null || !host.overlaps(guest)) return Path()..addRect(host);
//
//   final notchCenter = guest.center.dx;
//   final notchWidth = guest.width * 1.5;
//   final notchHeight = guest.height * 0.55;
//
//   final leftNotch = notchCenter - notchWidth / 2;
//   final rightNotch = notchCenter + notchWidth / 2;
//   final peakHeight = host.top - notchHeight;
//
//   final path = Path();
//
//   // Start with top-left corner
//   if (radius > 0) {
//     path.moveTo(host.left, host.top + radius);
//     path.arcToPoint(
//       Offset(host.left + radius, host.top),
//       radius: Radius.circular(radius),
//       clockwise: false,
//     );
//   } else {
//     path.moveTo(host.left, host.top);
//   }
//
//   // Line to left of notch
//   path.lineTo(leftNotch, host.top);
//
//   // Smooth left curve up to peak
//   path.cubicTo(
//     leftNotch + notchWidth * smoothness, host.top,             // Control point 1
//     notchCenter - notchWidth * smoothness, peakHeight,         // Control point 2
//     notchCenter, peakHeight,                                   // Peak
//   );
//
//   // Smooth right curve down
//   path.cubicTo(
//     notchCenter + notchWidth * smoothness, peakHeight,         // Control point 3
//     rightNotch - notchWidth * smoothness, host.top,            // Control point 4
//     rightNotch, host.top,
//   );
//
//   // Top-right corner
//   if (radius > 0) {
//     path.lineTo(host.right - radius, host.top);
//     path.arcToPoint(
//       Offset(host.right, host.top + radius),
//       radius: Radius.circular(radius),
//       clockwise: false,
//     );
//   } else {
//     path.lineTo(host.right, host.top);
//   }
//
//   // Remaining rectangle
//   path.lineTo(host.right, host.bottom);
//   path.lineTo(host.left, host.bottom);
//   path.close();
//
//   return path;
// }
}

/// A custom NotchedShape that draws a mountain-like notch with rounded corners.
// class MountainNotchedRectangle extends NotchedShape {
//   /// The depth (height) of the mountain peak from the top edge.
//   final double peakHeight;
//
//   /// The smoothness controls how round the edges and peak transitions are.
//   /// Typical values range from 0.1 to 0.3
//   final double smoothness;
//
//   const MountainNotchedRectangle({
//     this.peakHeight = 10.0,
//     this.smoothness = 0.2,
//   });
//
//   @override
//   Path getOuterPath(Rect host, Rect? guest) {
//     if (guest == null || !host.overlaps(guest)) {
//       return Path()..addRect(host);
//     }
//
//     final notchWidth = guest.width;
//     final notchCenter = guest.center.dx;
//     final leftNotch = notchCenter - notchWidth / 2;
//     final rightNotch = notchCenter + notchWidth / 2;
//
//     final path = Path();
//     path.moveTo(host.left, host.top);
//
//     // Left flat edge up to start of notch
//     path.lineTo(leftNotch, host.top);
//
//     // Mountain-like notch with rounded slopes
//     path.cubicTo(
//       leftNotch + notchWidth * smoothness, host.top,                     // Control point 1
//       notchCenter - notchWidth * smoothness, host.top - peakHeight,     // Control point 2
//       notchCenter, host.top - peakHeight,                                // Peak
//     );
//
//     path.cubicTo(
//       notchCenter + notchWidth * smoothness, host.top - peakHeight,     // Control point 3
//       rightNotch - notchWidth * smoothness, host.top,                   // Control point 4
//       rightNotch, host.top,                                              // End of notch
//     );
//
//     // Continue along the top right and rest of the bar
//     path.lineTo(host.right, host.top);
//     path.lineTo(host.right, host.bottom);
//     path.lineTo(host.left, host.bottom);
//     path.close();
//
//     return path;
//   }
// }
