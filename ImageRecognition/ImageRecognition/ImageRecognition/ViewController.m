//
//  ViewController.m
//  ImageRecognition
//
//  Created by 鲍利成 on 2017/6/20.
//  Copyright © 2017年 鲍利成. All rights reserved.
//

#import "ViewController.h"
#import "AppUtils.h"

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(nonatomic, strong) IBOutlet UITextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma -mark private functions
-(void)request: (NSString*)httpUrl withHttpArg: (NSString*)HttpArg  {
    NSURL *url = [NSURL URLWithString: httpUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL: url cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 10];
    [request setHTTPMethod: @"POST"];
    [request addValue: @"7df51b9f6b34e710f3cf698bc8a644b7" forHTTPHeaderField: @"apikey"];
    [request addValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
    NSData *data = [HttpArg dataUsingEncoding: NSUTF8StringEncoding];
    [request setHTTPBody: data];
    
    [AppUtils showLoadingInView:self.view];
    [NSURLConnection sendAsynchronousRequest: request
                                       queue: [NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error){
                               [AppUtils hiddenLoadingInView:self.view];
                               if (error) {
                                   NSLog(@"Httperror: %@%ld", error.localizedDescription, error.code);
                                   [AppUtils showInfo:error.localizedDescription];
                               } else {
                                   NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
                                   
                                   id resp = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:nil];
                                   
                                   if ([resp isKindOfClass:[NSDictionary class]]) {
                                       NSLog(@"%@",(NSDictionary *)resp);
                                   }
                                   
                                   NSInteger errorNo = [[resp objectForKey:@"errno"] integerValue];
                                   if (errorNo != 0) {
                                       [AppUtils showInfo:[resp objectForKey:@"errMsg"]];
                                       return;
                                   }
                                   NSArray *retData = resp[@"retData"];
                                   if (retData.count > 0) {
                                       NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] init];
                                       for (NSDictionary *item in retData) {
                                           NSString *str = [item objectForKey:@"word"];
                                           if (str) {
                                               NSAttributedString *aStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\r\n",str] attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15.0f],NSFontAttributeName, nil]];
                                               [attrStr appendAttributedString:aStr];
                                           }
                                           
                                       }
                                       
                                       [self.textView setAttributedText:attrStr];
                                   }
                                   //self.textView.text = responseString ;//设置它显示的内容
                               }
                           }];
}

- (NSString *)urlencode:(NSString*) data {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = [data UTF8String];
    int sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

-(void)imageRecognition:(UIImage *)image
{
    NSString *httpUrl = @"https://apis.baidu.com/idl_baidu/baiduocrpay/idlocrpaid";
    NSString *httpArg = [NSString string];
    httpArg = @"fromdevice=iPhone&clientip=10.10.10.0&detecttype=LocateRecognize&languagetype=CHN_ENG&imagetype=1&image=";
    NSData *data = UIImagePNGRepresentation(image);
    NSString* base64 = [data base64EncodedStringWithOptions:0];
    NSString* string = [self urlencode:base64];
    NSString* querydata = [httpArg stringByAppendingString:string];
    [self request: httpUrl withHttpArg: querydata];

}
#pragma -mark ButtonEvent
-(IBAction)clickCameraBtn:(id)sender
{
    UIImagePickerController *imgPicker=[[UIImagePickerController alloc]init];
    [imgPicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [imgPicker setDelegate:self];
    [imgPicker setAllowsEditing:YES];
    [self.navigationController presentViewController:imgPicker animated:YES completion:^{
        [self.textView setAttributedText:nil];
    }];
    
}

-(IBAction)clickPhotoBtn:(id)sender
{
    UIImagePickerController *imgPicker=[[UIImagePickerController alloc]init];
    [imgPicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imgPicker setDelegate:self];
    [imgPicker setAllowsEditing:YES];
    [self.navigationController presentViewController:imgPicker animated:YES completion:^{
        [self.textView setAttributedText:nil];
    }];
}
#pragma mark ----------图片选择完成-------------
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage  *picture= [info objectForKey:@"UIImagePickerControllerEditedImage"];
    UIImage *croppedImage = [AppUtils imageByScalingAndCroppingForSize:CGSizeMake(picture.size.width / 2.5f, picture.size.height / 2.5f) withSourceImage:picture];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [self imageRecognition:croppedImage];
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}
@end
