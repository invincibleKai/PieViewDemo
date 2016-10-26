//
//  YKPieView.m
//  YKPieView
//
//  Created by Kai_Yi on 2016/10/14.
//  Copyright © 2016年 Kai_Yi. All rights reserved.
//

#import "YKPieView.h"

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

@interface YKPieView ()

@property (nonatomic, strong) NSArray *colorArr;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) UIFont *labelFont;
@property (nonatomic, assign) CGFloat noDataTextMargin;

@property (nonatomic, strong) NSMutableArray *proportionArr; // 比例数组
@property (nonatomic, strong) NSMutableArray *radianArr; // 占圆比例数组
@property (nonatomic, strong) NSMutableArray *chartLineArr; // 环形图弧线数组
@property (nonatomic, strong) NSMutableArray *chartTextArr; // 文字数组
@property (nonatomic, assign) double startAngle;
@property (nonatomic, assign) double endAngle;
@property (nonatomic, assign) double total;

@property (strong,nonatomic) NSMutableDictionary *kerningCacheDictionary;
@property (strong, nonatomic) NSDictionary *textAttributes;
@property (nonatomic, assign) double characterSpacing;
@property (nonatomic, assign) CGFloat kerning;
@property (nonatomic, strong) UIFont *noDataFont;
@property (nonatomic, assign) CGFloat noDataFontNum;

@end

@implementation YKPieView

// 环形图的颜色
- (NSArray *)colorArr{
    if (!_colorArr) {
        _colorArr = @[RGB(39, 170, 225), RGB(255, 185, 80), RGB(218, 28, 92), RGB(88, 89, 91), RGB(133, 189, 44), RGB(51, 189, 155), RGB(112, 159, 205), RGB(149, 220, 223)];
    }
    return _colorArr;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.proportionArr = [NSMutableArray array];
        self.radianArr = [NSMutableArray array];
        self.chartLineArr = [NSMutableArray array];
        self.chartTextArr = [NSMutableArray array];
        
        self.kerningCacheDictionary = [NSMutableDictionary dictionary];
        
        self.labelFont = [UIFont systemFontOfSize:12];
        self.lineWidth = 60; // 环形图的线宽
        
        self.characterSpacing = 2.0; // 无数据时字符间距
        self.kerning = 30;
        self.noDataFontNum = 30;
        self.noDataFont = [UIFont systemFontOfSize:_noDataFontNum];
        self.textAttributes = @{
                                NSForegroundColorAttributeName : RGB(239, 239, 239),
                                NSFontAttributeName: _noDataFont
                                };
    }
    return self;
}

- (void)setShareArray:(NSArray *)shareArray{
    _shareArray = shareArray;
    if (_proportionArr.count) {
        [_proportionArr removeAllObjects];
    }
    if (_radianArr.count) {
        [_radianArr removeAllObjects];
    }
    if (_chartLineArr.count) {
        for (CAShapeLayer *chartLine in _chartLineArr) {
            [chartLine removeAllAnimations];
            [chartLine removeFromSuperlayer];
        }
        [_chartLineArr removeAllObjects];
    }
    if (_chartTextArr.count) {
        for (CATextLayer *textLayer in _chartTextArr) {
            [textLayer removeAllAnimations];
            [textLayer removeFromSuperlayer];
        }
        [_chartTextArr removeAllObjects];
    }
    
    self.total = 0.0;
    for (int i = 0; i < _shareArray.count; i ++) {
        self.total += [[_shareArray objectAtIndex:i] doubleValue];
    }
    
    for (int i = 0; i < _shareArray.count; i ++) {
        double proportion = [[_shareArray objectAtIndex:i] doubleValue] / (self.total == 0 ? 1 : self.total);
        double radian = proportion * M_PI * 2;
        [_proportionArr addObject:@(proportion)];
        [_radianArr addObject:@(radian)];
    }
    _startAngle = 0;
    _endAngle = 0;
}

- (void)reloadData{
    CGFloat centerX = CGRectGetWidth(self.frame) / 2;
    CGFloat centerY = CGRectGetHeight(self.frame) / 2;
    CGFloat radius =  MIN(centerX - _lineWidth * 0.5, centerY - _lineWidth * 0.5);
    if (self.total == 0) { // 当没有数据时绘制一圈灰色的圆环
        /*-----------------------圆弧layer-----------------------*/
        UIColor *noDataColor = RGB(239, 239, 239);
        CAShapeLayer *chartLine = [CAShapeLayer layer];
        [_chartLineArr addObject:chartLine];
        chartLine.strokeColor = [noDataColor CGColor];//绘制的线的颜色
        chartLine.fillColor = nil;
        chartLine.lineWidth = _lineWidth;//这里设置填充线的宽度，这个参数很重要
        chartLine.lineCap = kCALineCapButt;//设置线端点样式，这个也是非常重要的一个参数
        self.clipsToBounds = NO;//该属性表示如果图形绘制超过的容器的范围是否被裁掉，设置为YES ，表示要裁掉超出范围的绘制
        [self.layer addSublayer:chartLine];
        CGMutablePathRef pathRef  = CGPathCreateMutable();
        CGPathAddArc(pathRef, &CGAffineTransformIdentity, centerX, centerY, radius, 0, 2 * M_PI, NO);
        chartLine.path = pathRef;
        chartLine.strokeEnd = 1.0f;//表示绘制到百分比多少就停止，这个我们用1表示完全绘制
        /*-----------------------圆弧layer-----------------------*/
        
        /*-----------------------文字layer-----------------------*/
        NSString *noDataStr = @"没有数据";
        CGSize stringSize = [noDataStr sizeWithAttributes:self.textAttributes];
        float textRadius = radius;
        float circumference = 2 * textRadius * M_PI;
        float anglePerPixel = M_PI * 2 / circumference * self.characterSpacing;
        _startAngle = 270 * M_PI / 180 - (stringSize.width * anglePerPixel * 0.5);
        float characterPosition = 0;
        NSString *lastCharacter;
        for (int i = 0; i <noDataStr.length; i ++) {
            CATextLayer *textLayer = [CATextLayer layer];
            [_chartTextArr addObject:textLayer];
            textLayer.contentsScale = [[UIScreen mainScreen] scale];
            NSString *currentCharacter = [noDataStr substringWithRange:NSMakeRange(i, 1)];
            CGSize stringSize = [currentCharacter sizeWithAttributes:self.textAttributes];
            // 向characterPosition添加字符宽度的一半
            characterPosition += (stringSize.width / 2);
            // 计算字符角
            float angle = characterPosition * anglePerPixel + _startAngle;
            // 计算字符画点。
            CGPoint characterPoint = CGPointMake(textRadius * cos(angle) + centerX, textRadius * sin(angle) + centerY);
            // 字符串总是从左上角。计算正确的pos画在底部中心.
            CGPoint stringPoint = CGPointMake(characterPoint.x - stringSize.width * 0.5 , characterPoint.y - stringSize.height);
            textLayer.position = stringPoint;
            [textLayer setFontSize:_noDataFont.pointSize];
            [textLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
            [textLayer setAlignmentMode:kCAAlignmentCenter];
            [textLayer setString:currentCharacter];
            
            [textLayer setFrame:CGRectMake(stringPoint.x, stringPoint.y + _noDataFontNum * 0.5, stringSize.width, stringSize.height)];
            [CATransaction setDisableActions:NO];
            [self.layer addSublayer:textLayer];
            CATransform3D transform = CATransform3DMakeRotation(angle + M_PI_2, 0, 0, 0.5);
            textLayer.transform = transform;
            // 添加其他字符位置的字符长度的一半.
            characterPosition += stringSize.width * 0.5;
            // 如果达成了一个完整的循环停止.
            if (characterPosition * anglePerPixel >= M_PI * 2){
                break;
            }
            // currentCharacter使用存储在接下来的竞选字距调整计算.
            lastCharacter = currentCharacter;
        }
        /*-----------------------文字layer-----------------------*/
        return;
    }
    for (int i = 0; i < _shareArray.count; i ++) {
        _endAngle += [_radianArr[i] doubleValue];
        double averageAngle = (_startAngle + _endAngle) * 0.5;
        if (averageAngle > (M_PI * 0.5) && averageAngle <= (M_PI * 3 / 2)) {
            averageAngle = averageAngle - M_PI;
        }
        /*-----------------------圆弧layer-----------------------*/
        CAShapeLayer *chartLine = [CAShapeLayer layer];
        [_chartLineArr addObject:chartLine];
        int j = 0;
        if (i < self.colorArr.count) {
            j = i;
        }else{
            j = i % self.colorArr.count;
        }
        chartLine.strokeColor = [_colorArr[j] CGColor];//绘制的线的颜色
        chartLine.fillColor = nil;
        chartLine.lineWidth = _lineWidth;//这里设置填充线的宽度，这个参数很重要
        chartLine.lineCap = kCALineCapButt;//设置线端点样式，这个也是非常重要的一个参数
        self.clipsToBounds = NO;//该属性表示如果图形绘制超过的容器的范围是否被裁掉，设置为YES ，表示要裁掉超出范围的绘制
        [self.layer addSublayer:chartLine];
        
        CGMutablePathRef pathRef  = CGPathCreateMutable();
        CGPathAddArc(pathRef, &CGAffineTransformIdentity, centerX, centerY, radius, _startAngle, _endAngle, NO);
        chartLine.path = pathRef;
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = 1.0;//设置绘制动画持续的时间
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        pathAnimation.autoreverses = NO;//是否翻转绘制
        pathAnimation.fillMode = kCAFillModeForwards;
        pathAnimation.repeatCount = 1;
        
        [chartLine addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
        chartLine.strokeEnd = 1.0f;//表示绘制到百分比多少就停止，这个我们用1表示完全绘制
        /*-----------------------圆弧layer-----------------------*/
        
        /*-----------------------文字layer-----------------------*/
        CATextLayer *textLayer = [CATextLayer layer];
        [_chartTextArr addObject:textLayer];
        textLayer.contentsScale = [[UIScreen mainScreen] scale];
        NSString *str = [NSString stringWithFormat:@"%.2f%@",[_proportionArr[i] doubleValue] * 100, @"%"];
        if ([_proportionArr[i] doubleValue] < 0.02) { // 当占比小于 2% 时不显示
            str = @"";
        }
    
        CGFontRef font = nil;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            font = CGFontCreateCopyWithVariations((__bridge CGFontRef)(self.labelFont), (__bridge CFDictionaryRef)(@{}));
        } else {
            font = CGFontCreateWithFontName((__bridge CFStringRef)[self.labelFont fontName]);
        }
        if (font) {
            [textLayer setFont:font];
            CFRelease(font);
        }
        
        [textLayer setFontSize:self.labelFont.pointSize];
        [textLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
        [textLayer setAlignmentMode:kCAAlignmentCenter];
        [textLayer setString:str];
        
        CGSize size = [str sizeWithAttributes:@{NSFontAttributeName: self.labelFont}];
        [CATransaction setDisableActions:YES];
        [textLayer setFrame:CGRectMake(0, 0, size.width, size.height)];
        [textLayer setPosition:CGPointMake(centerX + (radius * cos((_startAngle + _endAngle) * 0.5)), centerY + (radius * sin((_startAngle + _endAngle) * 0.5)))];
        [CATransaction setDisableActions:NO];
        [self.layer addSublayer:textLayer];
        CATransform3D transform = CATransform3DMakeRotation(averageAngle, 0, 0, 0.5);
        textLayer.transform = transform;
        /*-----------------------文字layer-----------------------*/
        _startAngle = _endAngle;
    }
}

@end
