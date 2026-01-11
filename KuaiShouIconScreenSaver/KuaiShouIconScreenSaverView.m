//
//  KuaiShouIconScreenSaverView.m
//  KuaiShouIconScreenSaver
//
//  Created by 武翔宇 on 2026/1/9.
//

#import "KuaiShouIconScreenSaverView.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation KuaiShouIconScreenSaverView {
    NSTimeInterval _shapeSwitchTime; // 用于特殊位置图形切换的时间变量
    NSWindow *_configureWindow; // 配置窗口
    NSButton *_enableAnimationCheckbox; // 启用动效的复选框
}

// 节日结构
typedef struct {
    NSInteger month;
    NSInteger day;
    BOOL isLunar; // 是否为农历
    NSInteger weekDay; // 周几（0=周日，1=周一...），-1表示不限制
    NSInteger weekOrdinal; // 第几个周几（如第2个周日），-1表示不限制
    NSArray<NSString *> *emojis; // emoji数组
} FestivalInfo;

// 设置项的键名
static NSString * const kEnableAnimationKey = @"EnableAnimation";

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
        [self setAnimationTimeInterval:0.05]; // 改为0.05秒更新一次（20fps），以便实现平滑的morphing过渡
        _shapeSwitchTime = 0.0; // 初始化图形切换时间
    }
    return self;
}

// 获取是否启用动效设置（默认启用）
- (BOOL)isAnimationEnabled
{
    NSUserDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"KuaiShouIconScreenSaver"];
    if ([defaults objectForKey:kEnableAnimationKey] == nil) {
        return YES; // 默认启用
    }
    return [defaults boolForKey:kEnableAnimationKey];
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

// 获取农历日期
- (NSDateComponents *)getLunarDateComponents:(NSDate *)date
{
    NSCalendar *chineseCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierChinese];
    NSDateComponents *components = [chineseCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    return components;
}

// 获取阳历日期
- (NSDateComponents *)getSolarDateComponents:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:date];
    return components;
}

// 计算某个月的第N个周几
- (NSInteger)getWeekOrdinalForDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:date];
    
    NSInteger year = [components year];
    NSInteger month = [components month];
    NSInteger day = [components day];
    NSInteger weekday = [components weekday]; // 1=周日，2=周一...
    
    // 计算该月第一天是周几
    NSDateComponents *firstDayComponents = [[NSDateComponents alloc] init];
    [firstDayComponents setYear:year];
    [firstDayComponents setMonth:month];
    [firstDayComponents setDay:1];
    NSDate *firstDay = [calendar dateFromComponents:firstDayComponents];
    NSDateComponents *firstDayComps = [calendar components:NSCalendarUnitWeekday fromDate:firstDay];
    NSInteger firstWeekday = [firstDayComps weekday]; // 1=周日，2=周一...
    
    // 计算第一个目标周几出现在该月的第几天
    // 如果目标周几 >= 第一天周几，则第一个目标周几 = (目标周几 - 第一天周几) + 1
    // 如果目标周几 < 第一天周几，则第一个目标周几 = (7 - 第一天周几) + 目标周几 + 1
    NSInteger firstTargetDay;
    if (weekday >= firstWeekday) {
        firstTargetDay = (weekday - firstWeekday) + 1;
    } else {
        firstTargetDay = (7 - firstWeekday) + weekday + 1;
    }
    
    // 计算当前日期是第几个目标周几
    NSInteger weekOrdinal = (day - firstTargetDay) / 7 + 1;
    
    return weekOrdinal;
}

// 检测今天是否是节日，返回对应的emoji数组（支持多个节日同时匹配）
- (NSArray<NSString *> *)getFestivalEmojis
{
    // 测试模式：如果当前不是任何节日，显示测试emoji（可以删除或注释掉）
    // 为了确保今天能看到效果，可以临时启用这个测试模式
    BOOL enableTestMode = YES; // 设置为NO可以禁用测试模式
    
    NSDate *now = [NSDate date];
    NSDateComponents *solarComponents = [self getSolarDateComponents:now];
    NSDateComponents *lunarComponents = [self getLunarDateComponents:now];
    
    NSInteger solarMonth = [solarComponents month];
    NSInteger solarDay = [solarComponents day];
    NSInteger solarWeekday = [solarComponents weekday]; // 1=周日，2=周一...
    NSInteger solarWeekOrdinal = [self getWeekOrdinalForDate:now];
    
    NSInteger lunarMonth = [lunarComponents month];
    NSInteger lunarDay = [lunarComponents day];
    
    // 使用可变数组收集所有匹配的节日emoji
    NSMutableArray<NSString *> *emojis = [NSMutableArray array];
    
    // 定义节日列表（按时间顺序检查，支持多个节日同时匹配）
    // 1月1日 元旦 🎉⏰
    if (solarMonth == 1 && solarDay == 1) {
        [emojis addObjectsFromArray:@[@"🎉", @"🥂", @"🎆"]];
    }

    // 农历正月初一 春节 🧨🎇🍲
    if (lunarMonth == 1 && lunarDay == 1) {
        [emojis addObjectsFromArray:@[@"🧨", @"🏮", @"🥟"]];
    }
    
    // 农历2月14日 情人节 ❤️🌹💌
    if (lunarMonth == 2 && lunarDay == 14) {
        [emojis addObjectsFromArray:@[@"❤️", @"🌹", @"💌"]];
    }
    
    // 3月12日 植树节 🌳🌱🌏
    if (solarMonth == 3 && solarDay == 12) {
        [emojis addObjectsFromArray:@[@"🌳", @"🌱", @"🌏"]];
    }
    
    // 5月1日 劳动节 🛠️💼🌸
    if (solarMonth == 5 && solarDay == 1) {
        [emojis addObjectsFromArray:@[@"🛠️", @"💼", @"🌸"]];
    }
    
    // 5月4日 青年节 🏃‍♂️🌟
    if (solarMonth == 5 && solarDay == 4) {
        [emojis addObjectsFromArray:@[@"🏃‍♂️", @"🌟", @"💪"]];
    }
    
    // 5月第2个周日 母亲节 👩‍🦰💐❤️
    if (solarMonth == 5 && solarWeekday == 1 && solarWeekOrdinal == 2) {
        [emojis addObjectsFromArray:@[@"👩‍🦰", @"💐", @"❤️"]];
    }
    
    // 6月1日 儿童节 🧸🎈🍭
    if (solarMonth == 6 && solarDay == 1) {
        [emojis addObjectsFromArray:@[@"🧸", @"🎈", @"🍭"]];
    }
    
    // 6月第3个周日 父亲节 👨‍🦱🛠️💙
    if (solarMonth == 6 && solarWeekday == 1 && solarWeekOrdinal == 3) {
        [emojis addObjectsFromArray:@[@"👨‍🦱", @"🛠️", @"💙"]];
    }
    
    // 农历五月初五 端午节 🌾🛶
    if (lunarMonth == 5 && lunarDay == 5) {
        [emojis addObjectsFromArray:@[@"🌾", @"🛶", @"🍙"]];
    }
    
    // 农历七月初七 七夕节 💕🌌🎋
    if (lunarMonth == 7 && lunarDay == 7) {
        [emojis addObjectsFromArray:@[@"💕", @"🌌", @"🎋"]];
    }
    
    // 农历八月十五 中秋节 🌕🥮🏮
    if (lunarMonth == 8 && lunarDay == 15) {
        [emojis addObjectsFromArray:@[@"🥮", @"🌕", @"🐇"]];
    }
    
    // 9月10日 教师节 👩‍🏫🍎📚
    if (solarMonth == 9 && solarDay == 10) {
        [emojis addObjectsFromArray:@[@"👩‍🏫", @"🎓", @"📚"]];
    }
    
    // 农历九月初九 重阳节 🏔️🎗️☕
    if (lunarMonth == 9 && lunarDay == 9) {
        [emojis addObjectsFromArray:@[@"🏔️", @"🌼", @"🍵"]];
    }
    
    // 10月1日 国庆节 🇨🇳🎇🏞️
    if (solarMonth == 10 && solarDay == 1) {
        [emojis addObjectsFromArray:@[@"🇨🇳", @"🎇", @"🏮"]];
    }
    
    // 10月31日 万圣节 🎃👻🕸️
    if (solarMonth == 10 && solarDay == 31) {
        [emojis addObjectsFromArray:@[@"🎃", @"👻", @"🕸️"]];
    }
    
    // 12月25日 圣诞节 🎄🎅❄️
    if (solarMonth == 12 && solarDay == 25) {
        [emojis addObjectsFromArray:@[@"🎄", @"🎅", @"❄️"]];
    }
    
    // 农历十二月三十 除夕 🍲🎇🧨
    if (lunarMonth == 12 && lunarDay == 30) {
        [emojis addObjectsFromArray:@[@"🍲", @"🎇", @"🧨"]];
    }
    
    // 农历十二月初八 腊八节 🍲🥣
    if (lunarMonth == 12 && lunarDay == 8) {
        [emojis addObjectsFromArray:@[@"🍲", @"🥣", @"🌾"]];
    }
    
    // 如果匹配到任何节日，返回合并后的emoji数组
    if ([emojis count] > 0) {
        return [emojis copy];
    }
    
    // 测试模式：如果当前不是任何节日，显示测试emoji
    if (enableTestMode) {
        return @[@"🎉", @"⏰", @"🧨", @"🏮", @"🥟", @"🍙"]; // 显示元旦的emoji作为测试
    }
    
    return nil;
}

// 绘制emoji文本
- (void)drawEmoji:(NSString *)emoji atPoint:(NSPoint)point size:(CGFloat)size alpha:(CGFloat)alpha
{
    NSFont *font = [NSFont systemFontOfSize:size];
    NSColor *textColor = [[NSColor whiteColor] colorWithAlphaComponent:alpha];
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: textColor
    };
    
    NSSize textSize = [emoji sizeWithAttributes:attributes];
    NSPoint drawPoint = NSMakePoint(point.x - textSize.width / 2, point.y - textSize.height / 2);
    
    [emoji drawAtPoint:drawPoint withAttributes:attributes];
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
    [[NSColor colorWithWhite:0.2 alpha:0.6] setFill];
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
    [self drawShapeType:shapeType atPoint:point size:size filled:filled];
}

// 根据图形类型直接绘制图形（用于Morphing动画）
- (void)drawShapeType:(NSInteger)shapeType atPoint:(NSPoint)point size:(CGFloat)size filled:(BOOL)filled
{
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
    
    // 检测节日
    NSArray<NSString *> *festivalEmojis = [self getFestivalEmojis];
    BOOL isFestival = (festivalEmojis != nil && festivalEmojis.count > 0);
    
    // 计算中心行（1/2行，奇数行时直接取整）
    NSInteger centerRow = rows / 2; // 如果rows=24，centerRow=12（从0开始是第12行）
    
    // 计算当前最后一个isPast的位置
    // 如果超过22:00（currentMinute >= 720），则固定为第720个位置（索引719）
    NSInteger lastPastIndex = MIN(currentMinute, TOTAL_SHAPES - 1);
    
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
            
            // 如果是节日，在中心行显示emoji
            if (isFestival && row == centerRow && i < TOTAL_SHAPES) {
                // 计算这一行中emoji的显示位置（居中显示）
                NSInteger emojiCount = festivalEmojis.count;
                NSInteger startCol = (cols - emojiCount) / 2; // 起始列，使emoji居中
                NSInteger emojiIndex = col - startCol;
                
                // 如果当前列在emoji范围内，显示对应的emoji
                if (emojiIndex >= 0 && emojiIndex < emojiCount) {
                    NSString *emoji = festivalEmojis[emojiIndex];
                    CGFloat emojiSize = shapeSize * 1.2; // emoji稍大一些
                    // 判断当前位置是否已过去，未来时间使用半透明
                    BOOL isPast = (i <= currentMinute);
                    CGFloat alpha = isPast ? 1.0 : 0.5; // 过去时间完全不透明，未来时间半透明
                    [self drawEmoji:emoji atPoint:center size:emojiSize alpha:alpha];
                    continue; // 跳过默认图形的绘制
                }
            }
            
            // 如果超出720，绘制灰色填充的小圆
            if (i >= TOTAL_SHAPES) {
                [self drawGraySmallCircleAtPoint:center size:shapeSize];
            } else {
                // 判断是否已过去（包括当前分钟）
                // 如果当前是10:00，第一个图形（索引0）应该被填充
                BOOL isPast = (i <= currentMinute);
                
                // 在当前最后一个isPast的位置应用图形循环切换动效（带Morphing过渡）
                if (i == lastPastIndex && isPast) {
                    if ([self isAnimationEnabled]) {
                    // 计算当前应该显示的图形类型（0-3循环，每1秒一个周期）
                    NSInteger currentShapeType = ((NSInteger)_shapeSwitchTime) % SHAPE_TYPES;
                    NSInteger nextShapeType = (currentShapeType + 1) % SHAPE_TYPES;
                    
                    // 计算当前周期内的进度（0.0到1.0）
                    CGFloat cycleProgress = fmod(_shapeSwitchTime, 1.0);
                    
                    // 每个图形显示0.6秒，剩余0.4秒用于过渡
                    CGFloat displayDuration = 0.6;
                    CGFloat morphDuration = 0.4;
                    
                    if (cycleProgress < displayDuration) {
                        // 前0.6秒：正常显示当前图形
                        [self drawShapeType:currentShapeType atPoint:center size:shapeSize filled:isPast];
                    } else {
                        // 后0.4秒：进行Morphing过渡
                        CGFloat morphProgress = (cycleProgress - displayDuration) / morphDuration; // 0.0到1.0
                        
                        // 使用缓动函数（ease-in-out）让过渡更自然
                        CGFloat easedProgress = morphProgress < 0.5 
                            ? 2.0 * morphProgress * morphProgress 
                            : 1.0 - pow(-2.0 * morphProgress + 2.0, 2.0) / 2.0;
                        
                        // 前一个图形逐渐淡出并缩小
                        CGFloat prevAlpha = 1.0 - easedProgress;
                        CGFloat prevScale = 1.0 - easedProgress * 0.2; // 缩小到80%
                        
                        // 后一个图形逐渐淡入并放大
                        CGFloat nextAlpha = easedProgress;
                        CGFloat nextScale = 0.8 + easedProgress * 0.2; // 从80%放大到100%
                        
                        // 获取当前图形上下文
                        CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
                        
                        // 保存图形上下文状态
                        CGContextSaveGState(context);
                        
                        // 绘制前一个图形（淡出）
                        CGContextSetAlpha(context, prevAlpha);
                        [self drawShapeType:currentShapeType atPoint:center size:shapeSize * prevScale filled:isPast];
                        
                        // 绘制后一个图形（淡入）
                        CGContextSetAlpha(context, nextAlpha);
                        [self drawShapeType:nextShapeType atPoint:center size:shapeSize * nextScale filled:isPast];
                        
                        // 恢复图形上下文状态
                        CGContextRestoreGState(context);
                    }
                    } else {
                        // 动效未启用时，正常绘制当前图形
                        [self drawShapeAtIndex:i atPoint:center size:shapeSize filled:isPast];
                    }
                } else {
                    // 其他图形正常绘制
                    [self drawShapeAtIndex:i atPoint:center size:shapeSize filled:isPast];
                }
            }
        }
}

- (void)animateOneFrame
{
    // 更新图形切换时间（每0.05秒更新一次，每1秒切换一次图形，4个图形循环）
    _shapeSwitchTime += 0.05;
    [self setNeedsDisplay:YES];
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet
{
    // 如果窗口已存在且仍然可见，直接返回
    if (_configureWindow && [_configureWindow isVisible]) {
        return _configureWindow;
    }
    
    // 如果窗口已存在但不可见，清理子视图以便重新使用
    if (_configureWindow) {
        NSArray *subviews = [[_configureWindow.contentView subviews] copy];
        for (NSView *subview in subviews) {
            [subview removeFromSuperview];
        }
    } else {
        // 创建配置窗口
        NSRect windowRect = NSMakeRect(0, 0, 400, 200);
        _configureWindow = [[NSWindow alloc] initWithContentRect:windowRect
                                                       styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        [_configureWindow setTitle:@"快手图标屏保设置"];
        [_configureWindow center];
    }
    
    // 创建容器视图
    NSView *contentView = _configureWindow.contentView;
    
    // 创建复选框
    _enableAnimationCheckbox = [[NSButton alloc] initWithFrame:NSMakeRect(20, 120, 360, 30)];
    [_enableAnimationCheckbox setButtonType:NSButtonTypeSwitch];
    [_enableAnimationCheckbox setTitle:@"启用动态效果"];
    [_enableAnimationCheckbox setState:[self isAnimationEnabled] ? NSControlStateValueOn : NSControlStateValueOff];
    [_enableAnimationCheckbox setTarget:self];
    [_enableAnimationCheckbox setAction:@selector(enableAnimationChanged:)];
    [contentView addSubview:_enableAnimationCheckbox];
    
    // 创建确定按钮
    NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(200, 20, 80, 32)];
    [okButton setTitle:@"确定"];
    [okButton setButtonType:NSButtonTypeMomentaryPushIn];
    [okButton setBezelStyle:NSBezelStyleRounded];
    [okButton setTarget:self];
    [okButton setAction:@selector(okButtonClicked:)];
    [contentView addSubview:okButton];
    
    // 创建取消按钮
    NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(290, 20, 80, 32)];
    [cancelButton setTitle:@"取消"];
    [cancelButton setButtonType:NSButtonTypeMomentaryPushIn];
    [cancelButton setBezelStyle:NSBezelStyleRounded];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancelButtonClicked:)];
    [contentView addSubview:cancelButton];
    
    return _configureWindow;
}

// 复选框状态改变
- (void)enableAnimationChanged:(id)sender
{
    // 实时更新设置（但不保存，直到点击确定）
}

// 确定按钮点击
- (void)okButtonClicked:(id)sender
{
    // 保存设置
    NSUserDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"KuaiShouIconScreenSaver"];
    [defaults setBool:([_enableAnimationCheckbox state] == NSControlStateValueOn) forKey:kEnableAnimationKey];
    [defaults synchronize];
    
    // 关闭sheet窗口（只调用endSheet，不要调用close，也不要设置为nil）
    [NSApp endSheet:_configureWindow returnCode:NSModalResponseOK];
    
    // 触发重绘
    [self setNeedsDisplay:YES];
}

// 取消按钮点击
- (void)cancelButtonClicked:(id)sender
{
    // 关闭sheet窗口，不保存设置（只调用endSheet，不要调用close，也不要设置为nil）
    [NSApp endSheet:_configureWindow returnCode:NSModalResponseCancel];
}

@end
