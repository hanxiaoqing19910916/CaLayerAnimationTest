//
//  NSMutableAttributedString+CTFrameRef.m
//  SWAttributedLabel
//
//  Created by mxc235 on 16/8/31.
//  Copyright © 2016年 mxc235. All rights reserved.
//

#import "NSMutableAttributedString+CTFrameRef.h"
#import "SWAttributedImageInfo.h"
#import "NSMutableAttributedString+Config.h"


@implementation NSMutableAttributedString (CTFrameRef)

#pragma mark - NSRange / CFRange
NSRange NSRangeFromCFRange(CFRange range) {
    return NSMakeRange((NSUInteger)range.location, (NSUInteger)range.length);
}

#pragma mark - CoreText CTLine/CTRun utils
BOOL CTRunContainsCharactersFromStringRange(CTRunRef run, NSRange range) {
    NSRange runRange = NSRangeFromCFRange(CTRunGetStringRange(run));
    NSRange intersectedRange = NSIntersectionRange(runRange, range);
    return (intersectedRange.length <= 0);
}

BOOL CTLineContainsCharactersFromStringRange(CTLineRef line, NSRange range) {
    NSRange lineRange = NSRangeFromCFRange(CTLineGetStringRange(line));
    NSRange intersectedRange = NSIntersectionRange(lineRange, range);
    return (intersectedRange.length <= 0);
}

CGRect CTRunGetTypographicBoundsAsRect(CTRunRef run, CTLineRef line, CGPoint lineOrigin) {
    CGFloat ascent = 0.0f;
    CGFloat descent = 0.0f;
    CGFloat leading = 0.0f;
    CGFloat width = (CGFloat)CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
    CGFloat height = ascent + descent;
    
    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
    
    return CGRectMake(lineOrigin.x + xOffset - leading,
                      lineOrigin.y - descent,
                      width + leading,
                      height);
}

CGRect CTLineGetTypographicBoundsAsRect(CTLineRef line, CGPoint lineOrigin) {
    CGFloat ascent = 0.0f;
    CGFloat descent = 0.0f;
    CGFloat leading = 0.0f;
    CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CGFloat height = ascent + descent;
    
    return CGRectMake(lineOrigin.x,
                      lineOrigin.y - descent,
                      width,
                      height);
}

CGRect CTRunGetTypographicBoundsForLinkRect(CTLineRef line, NSRange range, CGPoint lineOrigin) {
    CGRect rectForRange = CGRectZero;
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    CFIndex runCount = CFArrayGetCount(runs);
    
    for (CFIndex k = 0; k < runCount; k++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, k);
        
        if (CTRunContainsCharactersFromStringRange(run, range)) {
            continue;
        }
        
        CGRect linkRect = CTRunGetTypographicBoundsAsRect(run, line, lineOrigin);
        
        linkRect.origin.y = roundf(linkRect.origin.y);
        linkRect.origin.x = roundf(linkRect.origin.x);
        linkRect.size.width = roundf(linkRect.size.width);
        linkRect.size.height = roundf(linkRect.size.height);
        
        rectForRange = CGRectIsEmpty(rectForRange) ? linkRect : CGRectUnion(rectForRange, linkRect);
    }
    
    return rectForRange;
}

CGRect CTRunGetTypographicBoundsForImageRect(CTRunRef run, CTLineRef line, CGPoint lineOrigin, SWAttributedImageInfo *imageData) {
    CGRect runBounds = CGRectZero;
    
    CGFloat ascent = 0.f;
    CGFloat descent = 0.f;
    CGFloat leading = 0.f;
    
    CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
    CGFloat lineHeight = ascent + descent + leading;
    CGFloat lineBottomY = lineOrigin.y - descent;
    
    runBounds.size.width = width;
    runBounds.size.height = imageData.imageSize.height;
    
    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
    runBounds.origin.x = lineOrigin.x + xOffset;
    
    // 设置Y坐标
    CGFloat imagePointY = 0.0f;
    CGFloat imageBoxHeight = imageData.imageSize.height;
    switch (imageData.imageAlignment) {
        case SWImageAlignmentTop:
            imagePointY = lineBottomY + (lineHeight - imageBoxHeight);
            break;
        case SWImageAlignmentCenter:
            imagePointY = lineBottomY + (lineHeight - imageBoxHeight) / 2.0;
            break;
        case SWImageAlignmentBottom:
            imagePointY = lineBottomY;
            break;
    }
    runBounds.origin.y = imagePointY;
    
    
    
    return UIEdgeInsetsInsetRect(runBounds, imageData.imageMargin);
}

CGRect UIEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
    rect.origin.x    += insets.left;
    rect.origin.y    += insets.top;
    rect.size.width  -= (insets.left + insets.right);
    rect.size.height -= (insets.top  + insets.bottom);
    return rect;
}

#pragma mark -
#pragma mark 获取label高度

- (CGFloat)getAttributedStringHeightWithString:(NSAttributedString *) string  WidthValue:(CGFloat) width
{
    CGFloat total_height = 0;
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);    //string 为要计算高度的NSAttributedString
    CGRect drawingRect = CGRectMake(0, 0, width, 1000);  //这里的高要设置足够大
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawingRect);
    CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);
    
    NSArray *linesArray = (NSArray *) CTFrameGetLines(textFrame);
    
    CGPoint origins[[linesArray count]];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
    
    int line_y = (int) origins[[linesArray count] -1].y;  //最后一行line的原点y坐标
    
    CGFloat ascent;
    CGFloat descent;
    CGFloat leading;
    
    CTLineRef line = (__bridge CTLineRef) [linesArray objectAtIndex:[linesArray count]-1];
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    
    total_height = 1000 - line_y +  descent ;    //+1为了纠正descent转换成int小数点后舍去的值
    
    CFRelease(textFrame);
    
    return total_height;
    
}

- (CGFloat)oneLineRealityWidth {
    CTLineRef  line = CTLineCreateWithAttributedString((CFAttributedStringRef) self);
    CGFloat ascent;
    CGFloat descent;
    CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
    return width;
}


- (CGFloat)realityHeightForWidth:(CGFloat)width {
    CGFloat realH =  [self realitySizeForWidth:width numberOfLines:0].height;
    return ceil(realH);
}

- (CGSize)realitySizeForWidth:(CGFloat)width
                numberOfLines:(NSUInteger)numberOfLines {
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self);
    
    // 获得要缓制的区域的高度
    CGSize restrictSize = CGSizeMake(width, CGFLOAT_MAX);
    CGSize coreTextSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), nil, restrictSize, nil);

    return CGSizeMake(ceil(coreTextSize.width), ceil(coreTextSize.height));
    
}

#pragma mark -
#pragma mark 获取CTFrameRef

- (CTFrameRef)prepareFrameRefWithRect:(CGRect)rect {
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, rect);
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, self.length), path, NULL);
    
    CGPathRelease(path);
    CFRelease(framesetter);
    
    return frameRef;
}

- (CTFrameRef)createFrameWithFramesetter:(CTFramesetterRef)framesetter
                                   width:(CGFloat)width
                                  height:(CGFloat)height {
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathAddRect(pathRef, NULL, CGRectMake(0, 0, width, height));
    
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), pathRef, NULL);
    CFRelease(pathRef);
    
    return frameRef;
}

@end
