//
//  ViewController.m
//  FaceRecognition
//
//  Created by 鲍利成 on 2017/6/21.
//  Copyright © 2017年 鲍利成. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppUtils.h"
#import "TBCityIconFont.h"
#import "UIImage+TBCityIconFont.h"

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    NSData *photoImage;
    NSData *cameraImage;
}
@property(nonatomic, strong) IBOutlet UIImageView *photoImageView;
@property(nonatomic, strong) IBOutlet UIImageView *cameraImageView;
@property(nonatomic, strong) IBOutlet UITextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [_photoImageView setImage:[UIImage iconWithInfo:TBCityIconInfoMake(@"\U0000e63b", 60, [UIColor grayColor])]];
    UITapGestureRecognizer *photoTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPhotoImageView)];
    [_photoImageView addGestureRecognizer:photoTapGesture];
    
    [_cameraImageView setImage:[UIImage iconWithInfo:TBCityIconInfoMake(@"\U0000e7e6", 60, [UIColor grayColor])]];
    UITapGestureRecognizer *cameraTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCameraImageView)];
    [_cameraImageView addGestureRecognizer:cameraTapGesture];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}
#pragma -mark request
-(void)compareFace:(NSString *)apiKey apiSecret:(NSString *)apiSecret firstImageData:(NSString *)firstImageData secondImageData:(NSString *)secondImageData
{
    NSString *url = @"https://api-cn.faceplusplus.com/facepp/v3/compare";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0f];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",@"boundary"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod: @"POST"];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:apiKey,@"api_key",apiSecret,@"api_secret",firstImageData,@"image_base64_1",secondImageData,@"image_base64_2", nil];
    NSData *data = [self bodyDataWithParam:params];
    [request setHTTPBody: data];
    [AppUtils showLoadingInView:self.view];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [AppUtils hiddenLoadingInView:self.view];
            if (!error) {
                NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                if (resultDic) {
                    NSMutableString *str = [[NSMutableString alloc] init];
                    id confidence = [resultDic objectForKey:@"confidence"];
                    if (confidence) {
                        double confidenceScore = [confidence doubleValue];
                        [str appendFormat:@"比对结果置信度:%.3f\r\n",confidenceScore];
                        
                        id thresholds = [resultDic objectForKey:@"thresholds"];
                        if (thresholds) {
                            id low = [thresholds objectForKey:@"1e-3"];
                            id normal = [thresholds objectForKey:@"1e-4"];
                            id high = [thresholds objectForKey:@"1e-5"];
                            [str appendFormat:@"参考置信度阈值:1e-3(%.3lf) 1e-4(%.3lf) 1e-5(%.3lf)\r\n\r\n",[low doubleValue],[normal doubleValue],[high doubleValue]];
                            
                            [str appendString:@"比对结果: "];
                            if (confidenceScore > [high doubleValue]) {
                                [str appendString:@"两副人脸是同一个人\r\n"];
                            }else if (confidenceScore < [low doubleValue]){
                                [str appendString:@"两副人脸不是同一个人\r\n"];
                            }else{
                                [str appendString:@"两副人脸可能为同一个人\r\n"];
                            }
                            
                            [str appendString:@"\r\n说明:比对结果置信度大于1e-5的阈值时，同一个人的几率非常高；比对结果置信度小于1e-3时，不建议认为是同一个人。"];
                            
                            [self.textView setText:str];
                        }
                    }else{
                        NSArray *faces1 = [resultDic objectForKey:@"faces1"];
                        NSArray *faces2 = [resultDic objectForKey:@"faces2"];
                        NSMutableString *str = [[NSMutableString alloc] init];
                        if (faces1 && faces1.count == 0) {
                            [str appendFormat:@"左边图像中未检测出人脸\r\n"];
                        }
                        
                        if (faces2 && faces2.count == 0) {
                            [str appendFormat:@"右边图像中未检测出人脸\r\n"];
                        }
                        [self.textView setText:str];
                    }
                }
            }else{
                [self.textView setText:error.localizedDescription];
            }
        });
        
    }];
    [postDataTask resume];
}


- (NSData *)bodyDataWithParam:(NSDictionary *)param{
    NSMutableData *bodyData = [NSMutableData data];
    //拼接参数
    [param enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [bodyData appendData:[@"--boundary\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
        [bodyData appendData:[[NSString stringWithFormat:@"%@\r\n",obj] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    [bodyData appendData:[@"--boundary--\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    return bodyData;
    
}
#pragma -mark private functions
-(void)getImageDetailInfo:(NSURL*)imageUrl callback:(void(^)(NSString *extName))callback{
    __block NSString* imageFileName;
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:imageUrl
                   resultBlock:^(ALAsset *myasset){
                       ALAssetRepresentation *representation = [myasset defaultRepresentation];
                       imageFileName = [representation filename];
                       NSArray *splitArr = [imageFileName componentsSeparatedByString:@"."];
                       if (splitArr && splitArr.count > 0) {
                           NSString *ext = [[splitArr lastObject] lowercaseString];
                           callback(ext);
                       }else{
                           callback(@"");
                       }
                   }
                  failureBlock:nil];
}

#pragma -mark ButtonEvent
-(IBAction)clickCompareBtn:(id)sender
{
    if (photoImage && cameraImage) {
        [self.textView setText:nil];
        NSString* photoImagebase64 = [photoImage base64EncodedStringWithOptions:0];
        NSString *cameraImagebase64 = [cameraImage base64EncodedStringWithOptions:0];
        [self compareFace:@"xlMBU_JTdDdNFk5mQTGL47ntFdWJ94-j" apiSecret:@"eB519QJw7KLyQoSKYW5huNpBYaBhtdQt" firstImageData:photoImagebase64 secondImageData:cameraImagebase64];
    }
}

#pragma -mark TabGestureRecognizer
-(void)tapPhotoImageView
{
    UIImagePickerController *imgPicker=[[UIImagePickerController alloc]init];
    [imgPicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imgPicker setDelegate:self];
    [imgPicker setAllowsEditing:YES];
    [self.navigationController presentViewController:imgPicker animated:YES completion:^{

    }];
}

-(void)tapCameraImageView
{
    UIImagePickerController *imgPicker=[[UIImagePickerController alloc]init];
    [imgPicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [imgPicker setDelegate:self];
    [imgPicker setAllowsEditing:YES];
    [self.navigationController presentViewController:imgPicker animated:YES completion:^{

    }];
}
#pragma mark ----------图片选择完成-------------
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.textView setAttributedText:nil];
    NSURL *imageUrl = [info valueForKey:UIImagePickerControllerReferenceURL];
    UIImage  *picture= [info objectForKey:@"UIImagePickerControllerEditedImage"];
//    UIImage *croppedImage = [AppUtils imageByScalingAndCroppingForSize:CGSizeMake(picture.size.width / 2.5f, picture.size.height / 2.5f) withSourceImage:picture];
    UIImage *croppedImage = picture;
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        switch (picker.sourceType) {
            case UIImagePickerControllerSourceTypePhotoLibrary:
            {
                [self getImageDetailInfo:imageUrl callback:^(NSString *extName) {
                    if ([extName isEqualToString:@"jpg"] || [extName isEqualToString:@"jpeg"]) {
                        photoImage = UIImageJPEGRepresentation(croppedImage, 1.0f);
                    }else{
                        photoImage = UIImagePNGRepresentation(croppedImage);
                    }
                }];
                [_photoImageView setImage:picture];
                [_photoImageView setContentMode:UIViewContentModeScaleAspectFit];
                break;
            }
            case UIImagePickerControllerSourceTypeCamera:
            {
                [self getImageDetailInfo:imageUrl callback:^(NSString *extName) {
                    if ([extName isEqualToString:@"jpg"] || [extName isEqualToString:@"jpeg"]) {
                        cameraImage = UIImageJPEGRepresentation(croppedImage, 1.0f);
                    }else{
                        cameraImage = UIImagePNGRepresentation(croppedImage);
                    }
                }];
                [_cameraImageView setImage:picture];
                [_cameraImageView setContentMode:UIViewContentModeScaleAspectFit];
                break;
            }
            default:
                break;
        }
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}
@end
