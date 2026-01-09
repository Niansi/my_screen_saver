//
//  KuaiShouIconScreenSaverView.m
//  KuaiShouIconScreenSaver
//
//  Created by 武翔宇 on 2026/1/9.
//

#import "KuaiShouIconScreenSaverView.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation KuaiShouIconScreenSaverView

// 快手橙色 RGB(255, 85, 0)
#define KUAI_SHOU_ORANGE_R 253.0/255.0
#define KUAI_SHOU_ORANGE_G 73.0/255.0
#define KUAI_SHOU_ORANGE_B 9.0/255.0

// 总图形数量
#define TOTAL_SHAPES 720
// 图形类型数量
#define SHAPE_TYPES 4
// 每种图形重复次数
#define REPEAT_COUNT 180

// 开始时间：10:00 AM
#define START_HOUR 10
// 结束时间：22:00 (10:00 PM)
#define END_HOUR 22
// 总分钟数
#define TOTAL_MINUTES 720

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:10.0];
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
    // 触发第一次绘制
    [self setNeedsDisplay:YES];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

// 获取当前时间对应的分钟数（从10:00开始计算）
- (NSInteger)currentMinuteFromStart
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:now];
    
    NSInteger currentHour = [components hour];
    NSInteger currentMinute = [components minute];
    
    // 如果当前时间早于10:00，返回0
    if (currentHour < START_HOUR) {
        return 0;
    }
    
    // 如果当前时间晚于22:00，返回720（全部完成）
    if (currentHour >= END_HOUR) {
        return TOTAL_MINUTES;
    }
    
    // 计算从10:00开始的分钟数
    NSInteger totalMinutes = (currentHour - START_HOUR) * 60 + currentMinute;
    
    return totalMinutes;
}

// 绘制大圆
- (void)drawLargeCircleAtPoint:(NSPoint)center size:(CGFloat)size filled:(BOOL)filled
{
    NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(center.x - size/2, center.y - size/2, size, size)];
    
    if (filled) {
        [[NSColor colorWithRed:KUAI_SHOU_ORANGE_R green:KUAI_SHOU_ORANGE_G blue:KUAI_SHOU_ORANGE_B alpha:1.0] setFill];
        [circle fill];
    } else {
        [[NSColor colorWithRed:KUAI_SHOU_ORANGE_R green:KUAI_SHOU_ORANGE_G blue:KUAI_SHOU_ORANGE_B alpha:1.0] setStroke];
        [circle setLineWidth:0.5];
        [circle stroke];
    }
}

// 绘制小圆
- (void)drawSmallCircleAtPoint:(NSPoint)center size:(CGFloat)size filled:(BOOL)filled
{
    NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(center.x - size/2, center.y - size/2, size, size)];
    
    if (filled) {
        [[NSColor colorWithRed:KUAI_SHOU_ORANGE_R green:KUAI_SHOU_ORANGE_G blue:KUAI_SHOU_ORANGE_B alpha:1.0] setFill];
        [circle fill];
    } else {
        [[NSColor colorWithRed:KUAI_SHOU_ORANGE_R green:KUAI_SHOU_ORANGE_G blue:KUAI_SHOU_ORANGE_B alpha:1.0] setStroke];
        [circle setLineWidth:0.5];
        [circle stroke];
    }
}

// 绘制灰色填充的小圆（用于超出720的部分）
- (void)drawGraySmallCircleAtPoint:(NSPoint)center size:(CGFloat)size
{
    CGFloat smallSize = size * 0.5;
    NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(center.x - smallSize/2, center.y - smallSize/2, smallSize, smallSize)];
    
    // 使用深灰色填充（更接近黑色）
    [[NSColor colorWithWhite:0.2 alpha:1.0] setFill];
    [circle fill];
}

// 绘制圆角三角形（向右指向，类似播放按钮）
- (void)drawRoundedTriangleAtPoint:(NSPoint)center size:(CGFloat)size filled:(BOOL)filled
{
    // 确保size有效
    if (size <= 0) {
        return;
    }
    
    CGFloat radius = size * 0.25; // 圆角半径
    
    // 计算三角形的三个顶点（向右指向的三角形，类似播放按钮）
    CGPoint right = CGPointMake(center.x + size/2, center.y); // 右侧尖角
    CGPoint topLeft = CGPointMake(center.x - size/2, center.y + size/2); // 左上角
    CGPoint bottomLeft = CGPointMake(center.x - size/2, center.y - size/2); // 左下角
    
    // 使用 NSBezierPath 绘制圆角三角形，使用二次贝塞尔曲线创建圆角
    NSBezierPath *triangle = [NSBezierPath bezierPath];
    
    // 计算每个角的两条边的方向向量和单位向量
    // 右侧角：从right到topLeft，从right到bottomLeft
    CGPoint vecRightToTop = CGPointMake(topLeft.x - right.x, topLeft.y - right.y);
    CGFloat lenRightToTop = sqrt(vecRightToTop.x * vecRightToTop.x + vecRightToTop.y * vecRightToTop.y);
    CGPoint unitRightToTop = CGPointMake(vecRightToTop.x / lenRightToTop, vecRightToTop.y / lenRightToTop);
    
    CGPoint vecRightToBottom = CGPointMake(bottomLeft.x - right.x, bottomLeft.y - right.y);
    CGFloat lenRightToBottom = sqrt(vecRightToBottom.x * vecRightToBottom.x + vecRightToBottom.y * vecRightToBottom.y);
    CGPoint unitRightToBottom = CGPointMake(vecRightToBottom.x / lenRightToBottom, vecRightToBottom.y / lenRightToBottom);
    
    // 左上角：从topLeft到right，从topLeft到bottomLeft
    CGPoint vecTopToRight = CGPointMake(right.x - topLeft.x, right.y - topLeft.y);
    CGFloat lenTopToRight = sqrt(vecTopToRight.x * vecTopToRight.x + vecTopToRight.y * vecTopToRight.y);
    CGPoint unitTopToRight = CGPointMake(vecTopToRight.x / lenTopToRight, vecTopToRight.y / lenTopToRight);
    
    CGPoint vecTopToBottom = CGPointMake(bottomLeft.x - topLeft.x, bottomLeft.y - topLeft.y);
    CGFloat lenTopToBottom = sqrt(vecTopToBottom.x * vecTopToBottom.x + vecTopToBottom.y * vecTopToBottom.y);
    CGPoint unitTopToBottom = CGPointMake(vecTopToBottom.x / lenTopToBottom, vecTopToBottom.y / lenTopToBottom);
    
    // 左下角：从bottomLeft到topLeft，从bottomLeft到right
    CGPoint vecBottomToTop = CGPointMake(topLeft.x - bottomLeft.x, topLeft.y - bottomLeft.y);
    CGFloat lenBottomToTop = sqrt(vecBottomToTop.x * vecBottomToTop.x + vecBottomToTop.y * vecBottomToTop.y);
    CGPoint unitBottomToTop = CGPointMake(vecBottomToTop.x / lenBottomToTop, vecBottomToTop.y / lenBottomToTop);
    
    CGPoint vecBottomToRight = CGPointMake(right.x - bottomLeft.x, right.y - bottomLeft.y);
    CGFloat lenBottomToRight = sqrt(vecBottomToRight.x * vecBottomToRight.x + vecBottomToRight.y * vecBottomToRight.y);
    CGPoint unitBottomToRight = CGPointMake(vecBottomToRight.x / lenBottomToRight, vecBottomToRight.y / lenBottomToRight);
    
    // 计算每个角的切点（从顶点沿着边向内移动radius距离）
    CGPoint rightPoint1 = CGPointMake(right.x + unitRightToTop.x * radius, right.y + unitRightToTop.y * radius);
    CGPoint rightPoint2 = CGPointMake(right.x + unitRightToBottom.x * radius, right.y + unitRightToBottom.y * radius);
    CGPoint topPoint1 = CGPointMake(topLeft.x + unitTopToRight.x * radius, topLeft.y + unitTopToRight.y * radius);
    CGPoint topPoint2 = CGPointMake(topLeft.x + unitTopToBottom.x * radius, topLeft.y + unitTopToBottom.y * radius);
    CGPoint bottomPoint1 = CGPointMake(bottomLeft.x + unitBottomToTop.x * radius, bottomLeft.y + unitBottomToTop.y * radius);
    CGPoint bottomPoint2 = CGPointMake(bottomLeft.x + unitBottomToRight.x * radius, bottomLeft.y + unitBottomToRight.y * radius);
    
    // 检查切点是否有效（避免NaN或无效值）
    if (isnan(rightPoint1.x) || isnan(rightPoint1.y) || 
        isnan(rightPoint2.x) || isnan(rightPoint2.y) ||
        isnan(topPoint1.x) || isnan(topPoint1.y) ||
        isnan(topPoint2.x) || isnan(topPoint2.y) ||
        isnan(bottomPoint1.x) || isnan(bottomPoint1.y) ||
        isnan(bottomPoint2.x) || isnan(bottomPoint2.y)) {
        // 如果切点无效，绘制普通三角形
        NSBezierPath *simpleTriangle = [NSBezierPath bezierPath];
        [simpleTriangle moveToPoint:NSMakePoint(right.x, right.y)];
        [simpleTriangle lineToPoint:NSMakePoint(topLeft.x, topLeft.y)];
        [simpleTriangle lineToPoint:NSMakePoint(bottomLeft.x, bottomLeft.y)];
        [simpleTriangle closePath];
        NSColor *orangeColor = [NSColor colorWithRed:KUAI_SHOU_ORANGE_R green:KUAI_SHOU_ORANGE_G blue:KUAI_SHOU_ORANGE_B alpha:1.0];
        if (filled) {
            [orangeColor setFill];
            [simpleTriangle fill];
        } else {
            [orangeColor setStroke];
            [simpleTriangle setLineWidth:0.5];
            [simpleTriangle stroke];
        }
        return;
    }
    
    // 从右侧开始绘制
    [triangle moveToPoint:NSMakePoint(rightPoint1.x, rightPoint1.y)];
    
    // 直线到左上角的第一个切点
    [triangle lineToPoint:NSMakePoint(topPoint1.x, topPoint1.y)];
    
    // 使用二次贝塞尔曲线从topPoint1到topPoint2，创建圆角效果
    // 控制点是左上角顶点
    [triangle curveToPoint:NSMakePoint(topPoint2.x, topPoint2.y)
             controlPoint1:NSMakePoint(topLeft.x, topLeft.y)
             controlPoint2:NSMakePoint(topLeft.x, topLeft.y)];
    
    // 直线到左下角的第一个切点
    [triangle lineToPoint:NSMakePoint(bottomPoint1.x, bottomPoint1.y)];
    
    // 使用二次贝塞尔曲线从bottomPoint1到bottomPoint2，创建圆角效果
    [triangle curveToPoint:NSMakePoint(bottomPoint2.x, bottomPoint2.y)
             controlPoint1:NSMakePoint(bottomLeft.x, bottomLeft.y)
             controlPoint2:NSMakePoint(bottomLeft.x, bottomLeft.y)];
    
    // 直线回到右侧的第二个切点
    [triangle lineToPoint:NSMakePoint(rightPoint2.x, rightPoint2.y)];
    
    // 使用二次贝塞尔曲线从rightPoint2到rightPoint1，创建圆角效果
    [triangle curveToPoint:NSMakePoint(rightPoint1.x, rightPoint1.y)
             controlPoint1:NSMakePoint(right.x, right.y)
             controlPoint2:NSMakePoint(right.x, right.y)];
    
    [triangle closePath];
    
    NSColor *orangeColor = [NSColor colorWithRed:KUAI_SHOU_ORANGE_R green:KUAI_SHOU_ORANGE_G blue:KUAI_SHOU_ORANGE_B alpha:1.0];
    
    if (filled) {
        [orangeColor setFill];
        [triangle fill];
    } else {
        [orangeColor setStroke];
        [triangle setLineWidth:0.5];
        [triangle stroke];
    }
}

// 绘制圆角长方形
- (void)drawRoundedRectangleAtPoint:(NSPoint)center size:(CGFloat)size filled:(BOOL)filled
{
    CGFloat width = size * 0.8;
    CGFloat height = size * 0.6;
    CGFloat radius = size * 0.15; // 圆角半径
    
    NSRect rect = NSMakeRect(center.x - width/2, center.y - height/2, width, height);
    NSBezierPath *roundedRect = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
    
    if (filled) {
        [[NSColor colorWithRed:KUAI_SHOU_ORANGE_R green:KUAI_SHOU_ORANGE_G blue:KUAI_SHOU_ORANGE_B alpha:1.0] setFill];
        [roundedRect fill];
    } else {
        [[NSColor colorWithRed:KUAI_SHOU_ORANGE_R green:KUAI_SHOU_ORANGE_G blue:KUAI_SHOU_ORANGE_B alpha:1.0] setStroke];
        [roundedRect setLineWidth:0.5];
        [roundedRect stroke];
    }
}

// 根据索引绘制图形
- (void)drawShapeAtIndex:(NSInteger)index atPoint:(NSPoint)point size:(CGFloat)size filled:(BOOL)filled
{
    NSInteger shapeType = index % SHAPE_TYPES;
    
    switch (shapeType) {
        case 0: // 大圆
            [self drawLargeCircleAtPoint:point size:size filled:filled];
            break;
        case 1: // 小圆
            [self drawSmallCircleAtPoint:point size:size * 0.74 filled:filled];
            break;
        case 2: // 圆角三角形
            [self drawRoundedTriangleAtPoint:point size:size * 0.74 filled:filled];
            break;
        case 3: // 圆角长方形
            [self drawRoundedRectangleAtPoint:point size:size * 1.1 filled:filled];
            break;
    }
}

- (void)drawRect:(NSRect)rect
{
    // 设置黑色背景
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    
    // 获取当前时间对应的分钟数
    NSInteger currentMinute = [self currentMinuteFromStart];
    
    // 计算布局参数
    NSRect bounds = [self bounds];
    
    // 检查bounds是否有效
    if (bounds.size.width <= 0 || bounds.size.height <= 0) {
        return;
    }
    
    CGFloat margin = 40.0;
    CGFloat availableWidth = bounds.size.width - margin * 2;
    CGFloat availableHeight = bounds.size.height - margin * 2;
    
    // 检查可用空间是否有效
    if (availableWidth <= 0 || availableHeight <= 0) {
        return;
    }
    
    // 根据屏幕宽高比自动计算最佳行列数，使图形尽可能接近正方形
    CGFloat aspectRatio = availableWidth / availableHeight;
    
    // MacBook Pro标准显示器（2056×1329，宽高比≈1.547）优先使用30×24
    // 如果宽高比在1.5-1.6之间，直接使用30×24
    NSInteger cols, rows;
    if (aspectRatio >= 1.5 && aspectRatio <= 1.6) {
        cols = 30;
        rows = 24;
    } else {
        // 其他分辨率，尝试不同的行列组合，找到最接近正方形的布局
        CGFloat bestRatio = MAXFLOAT;
        NSInteger bestCols = 30;
        NSInteger bestRows = 24;
        
        // 尝试几种常见的布局组合
        NSArray *layouts = @[
            @[@42, @18],  // 超宽屏
            @[@38, @19],  // 超宽屏
            @[@34, @22],  // 宽屏
            @[@30, @24],  // 标准
            @[@26, @28],  // 竖屏
            @[@22, @33],  // 超竖屏
            @[@18, @40]   // 超竖屏
        ];
        
        for (NSArray *layout in layouts) {
            NSInteger testCols = [layout[0] integerValue];
            NSInteger testRows = [layout[1] integerValue];
            
            // 允许超出720，不再限制必须等于TOTAL_SHAPES
            
            CGFloat testCellWidth = availableWidth / testCols;
            CGFloat testCellHeight = availableHeight / testRows;
            CGFloat ratio = fabs(testCellWidth / testCellHeight - 1.0); // 越接近0越好（即越接近正方形）
            
            if (ratio < bestRatio) {
                bestRatio = ratio;
                bestCols = testCols;
                bestRows = testRows;
            }
        }
        
        cols = bestCols;
        rows = bestRows;
    }
    
    CGFloat cellWidth = availableWidth / cols;
    CGFloat cellHeight = availableHeight / rows;
    CGFloat shapeSize = MIN(cellWidth, cellHeight) * 0.6; // 图形大小
    
    // 确保图形大小有效
    if (shapeSize <= 0) {
        return;
    }
    
    // 绘制所有图形（允许超出720）
    NSInteger totalCells = cols * rows;
    for (NSInteger i = 0; i < totalCells; i++) {
        NSInteger row = i / cols;
        NSInteger col = i % cols;
        
        // 反转y坐标，让row=0对应顶部，row=rows-1对应底部（macOS坐标系y从下往上）
        NSPoint center = NSMakePoint(
            margin + col * cellWidth + cellWidth / 2,
            margin + (rows - 1 - row) * cellHeight + cellHeight / 2
        );
        
        // 如果超出720，绘制灰色填充的小圆
        if (i >= TOTAL_SHAPES) {
            [self drawGraySmallCircleAtPoint:center size:shapeSize];
        } else {
            // 判断是否已过去（包括当前分钟）
            // 如果当前是10:00，第一个图形（索引0）应该被填充
            BOOL isPast = (i <= currentMinute);
            
            [self drawShapeAtIndex:i atPoint:center size:shapeSize filled:isPast];
        }
    }
}

- (void)animateOneFrame
{
    [self setNeedsDisplay:YES];
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
