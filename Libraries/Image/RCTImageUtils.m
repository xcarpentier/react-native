/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTImageUtils.h"

#import "RCTLog.h"

CGSize RCTTargetSizeForClipRect(CGRect clipRect)
{
  return (CGSize){
    clipRect.size.width + clipRect.origin.x * 2,
    clipRect.size.height + clipRect.origin.y * 2
  };
}

CGRect RCTClipRect(CGSize sourceSize, CGFloat sourceScale,
                   CGSize destSize, CGFloat destScale,
                   UIViewContentMode resizeMode)
{
  if (CGSizeEqualToSize(destSize, CGSizeZero)) {
    // Assume we require the largest size available
    return (CGRect){CGPointZero, sourceSize};
  }

  // Precompensate for scale
  CGFloat scale = sourceScale / destScale;
  sourceSize.width *= scale;
  sourceSize.height *= scale;

  // Calculate aspect ratios if needed (don't bother if resizeMode == stretch)
  CGFloat aspect = 0.0, targetAspect = 0.0;
  if (resizeMode != UIViewContentModeScaleToFill) {
    aspect = sourceSize.width / sourceSize.height;
    targetAspect = destSize.width / destSize.height;
    if (aspect == targetAspect) {
      resizeMode = UIViewContentModeScaleToFill;
    }
  }

  switch (resizeMode) {
    case UIViewContentModeScaleToFill: // stretch

      sourceSize.width = MIN(destSize.width, sourceSize.width);
      sourceSize.height = MIN(destSize.height, sourceSize.height);
      return (CGRect){CGPointZero, sourceSize};

    case UIViewContentModeScaleAspectFit: // contain

      if (targetAspect <= aspect) { // target is taller than content

        sourceSize.width = destSize.width = MIN(sourceSize.width, destSize.width);
        sourceSize.height = sourceSize.width / aspect;

      } else { // target is wider than content

        sourceSize.height = destSize.height = MIN(sourceSize.height, destSize.height);
        sourceSize.width = sourceSize.height * aspect;
      }
      return (CGRect){CGPointZero, sourceSize};

    case UIViewContentModeScaleAspectFill: // cover

      if (targetAspect <= aspect) { // target is taller than content

        sourceSize.height = destSize.height = MIN(sourceSize.height, destSize.height);
        sourceSize.width = sourceSize.height * aspect;
        destSize.width = destSize.height * targetAspect;
        return (CGRect){{(destSize.width - sourceSize.width) / 2, 0}, sourceSize};

      } else { // target is wider than content

        sourceSize.width = destSize.width = MIN(sourceSize.width, destSize.width);
        sourceSize.height = sourceSize.width / aspect;
        destSize.height = destSize.width / targetAspect;
        return (CGRect){{0, (destSize.height - sourceSize.height) / 2}, sourceSize};
      }

    default:

      RCTLogError(@"A resizeMode value of %zd is not supported", resizeMode);
      return (CGRect){CGPointZero, destSize};
  }
}

RCT_EXTERN BOOL RCTUpscalingRequired(CGSize sourceSize, CGFloat sourceScale,
                                     CGSize destSize, CGFloat destScale,
                                     UIViewContentMode resizeMode)
{
  if (CGSizeEqualToSize(destSize, CGSizeZero)) {
    // Assume we require the largest size available
    return YES;
  }

  // Precompensate for scale
  CGFloat scale = sourceScale / destScale;
  sourceSize.width *= scale;
  sourceSize.height *= scale;

  // Calculate aspect ratios if needed (don't bother if resizeMode == stretch)
  CGFloat aspect = 0.0, targetAspect = 0.0;
  if (resizeMode != UIViewContentModeScaleToFill) {
    aspect = sourceSize.width / sourceSize.height;
    targetAspect = destSize.width / destSize.height;
    if (aspect == targetAspect) {
      resizeMode = UIViewContentModeScaleToFill;
    }
  }

  switch (resizeMode) {
    case UIViewContentModeScaleToFill: // stretch

      return destSize.width > sourceSize.width || destSize.height > sourceSize.height;

    case UIViewContentModeScaleAspectFit: // contain

      if (targetAspect <= aspect) { // target is taller than content

        return destSize.width > sourceSize.width;

      } else { // target is wider than content

        return destSize.height > sourceSize.height;
      }

    case UIViewContentModeScaleAspectFill: // cover

      if (targetAspect <= aspect) { // target is taller than content

        return destSize.height > sourceSize.height;

      } else { // target is wider than content

        return destSize.width > sourceSize.width;
      }

    default:

      RCTLogError(@"A resizeMode value of %zd is not supported", resizeMode);
      return NO;
  }
}
