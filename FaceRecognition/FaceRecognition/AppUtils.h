//
//  AppUtils.h
//  GLPFinance
//
//  Created by 鲍利成 on 16/10/28.
//  Copyright © 2016年 鲍利成. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AppUtils : NSObject
/**
 提示控件

 @param text 提示文本
 */
+(void)showInfo:(NSString *)text;

+(void)showLoadingInView:(UIView *)view;
+(void)hiddenLoadingInView:(UIView *)view;
+ (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize withSourceImage:(UIImage *)sourceImage;
@end
