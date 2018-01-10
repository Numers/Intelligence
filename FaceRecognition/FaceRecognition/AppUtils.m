//
//  AppUtils.m
//  GLPFinance
//
//  Created by 鲍利成 on 16/10/28.
//  Copyright © 2016年 鲍利成. All rights reserved.
//

#import "AppUtils.h"
#import "MBProgressHUD.h"
#import "FeThreeDotGlow.h"
#define MBTAG  1001 //显示文本的提示tag
#define MBProgressThreeDotViewTAG 1006 //加载三点的控件tag
@implementation AppUtils
+(void)showInfo:(NSString *)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *appRootView = [UIApplication sharedApplication].keyWindow;
        MBProgressHUD *HUD = (MBProgressHUD *)[appRootView viewWithTag:MBTAG];
        if (HUD == nil) {
            HUD = [[MBProgressHUD alloc] initWithView:appRootView];
            HUD.tag = MBTAG;
            [appRootView addSubview:HUD];
            [HUD showAnimated:YES];
        }
        
        HUD.removeFromSuperViewOnHide = YES; // 设置YES ，MB 再消失的时候会从super 移除
        
        if ([self isNullStr:text]) {
            //        HUD.animationType = MBProgressHUDAnimationZoom;
            [HUD hideAnimated:YES];
        }else{
            HUD.mode = MBProgressHUDModeText;
            HUD.label.text = text;
            HUD.label.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
            [HUD hideAnimated:YES afterDelay:1];
        }
    });
}

+(void)showLoadingInView:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        FeThreeDotGlow *threeDotGlow = [view viewWithTag:MBProgressThreeDotViewTAG];
        if (threeDotGlow == nil) {
            threeDotGlow = [[FeThreeDotGlow alloc] initWithView:view blur:NO];
            threeDotGlow.tag = MBProgressThreeDotViewTAG;
            [view addSubview:threeDotGlow];
        }
        [threeDotGlow show];
    });
}

+(void)hiddenLoadingInView:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        FeThreeDotGlow *threeDotGlow = [view viewWithTag:MBProgressThreeDotViewTAG];
        if (threeDotGlow != nil) {
            [threeDotGlow dismiss];
            [threeDotGlow removeFromSuperview];
            threeDotGlow = nil;
        }
    });
}

+ (BOOL)isNullStr:(NSString *)str
{
    if (str == nil || [str isEqual:[NSNull null]] || str.length == 0) {
        return  YES;
    }
    
    return NO;
}

/**
 * 图片压缩到指定大小
 * @param targetSize 目标图片的大小
 * @param sourceImage 源图片
 * @return 目标图片
 */
+ (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize withSourceImage:(UIImage *)sourceImage
{
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth= width * scaleFactor;
        scaledHeight = height * scaleFactor;
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else if (widthFactor < heightFactor)
        {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width= scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil)
        NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
}
@end
