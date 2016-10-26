//
//  YKPieController.m
//  YKPieView
//
//  Created by Kai_Yi on 2016/10/14.
//  Copyright © 2016年 Kai_Yi. All rights reserved.
//

#import "YKPieController.h"
#import "YKPieView.h"


#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface YKPieController ()
@property (nonatomic, strong) YKPieView *pieView;
@property (nonatomic, strong) CATextLayer *textLayer;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIView* bgView;

@property (nonatomic, strong) UIView *containerView;

@end

@implementation YKPieController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.pieView = [[YKPieView alloc] initWithFrame:CGRectMake(25, 100, 300, 300)];
    NSMutableArray *tempArr = [NSMutableArray array];
    for (int i = 1; i <= 20; i++) {
        [tempArr addObject:@(i)];
    }
    self.pieView.shareArray = [tempArr copy];
    [self.pieView reloadData];
    [self.view addSubview:self.pieView];
    
    NSArray *titleArr = @[@"有数据时", @"没数据时"];
    NSArray *colorArr = @[[UIColor redColor], [UIColor blueColor]];
    for (int i = 0; i < 2; i ++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(i * self.view.frame.size.width * 0.5, self.view.frame.size.height - 80, self.view.frame.size.width * 0.5, 80)];
        [button setTitle:titleArr[i] forState:UIControlStateNormal];
        button.backgroundColor = colorArr[i];
        button.tag = 250 + i;
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
    
}

- (void)buttonClick:(UIButton *)button{
    if (button.tag == 250) {
        NSMutableArray *tempArr = [NSMutableArray array];
        for (int i = 1; i <= 20; i++) {
            [tempArr addObject:@(i)];
        }
        self.pieView.shareArray = [tempArr copy];
        [self.pieView reloadData];
    }else if (button.tag == 251){
        self.pieView.shareArray = @[@0, @0, @0, @0];
        [self.pieView reloadData];
    }
}

@end
