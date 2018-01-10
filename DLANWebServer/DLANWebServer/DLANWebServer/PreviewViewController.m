//
//  PreviewViewController.m
//  DLANWebServer
//
//  Created by 鲍利成 on 2017/10/27.
//  Copyright © 2017年 鲍利成. All rights reserved.
//

#import "PreviewViewController.h"
#import <WebKit/WKWebView.h>

@interface PreviewViewController ()
{
    NSString *loadUrl;
}
@property(nonatomic, strong) WKWebView *webView;
@end

@implementation PreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    [self.navigationItem setLeftBarButtonItem:leftItem];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    [self.navigationItem setRightBarButtonItem:rightItem];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadFile:(NSString *)filePath
{
    if(filePath){
        loadUrl = filePath;
        //带编码头的如utf-8，这里会识别出来
        NSString *body = [NSString stringWithContentsOfFile:filePath usedEncoding:nil error:nil];
        if(!body){
            //按GBK编码再解码一次
            body = [NSString stringWithContentsOfFile:filePath usedEncoding:0x80000632 error:nil];
        }
        //还是识别不出，就按GB18030编码再解码一次
        if(!body){
            body = [NSString stringWithContentsOfFile:filePath usedEncoding:0x80000631 error:nil];
        }
        
        if(body){
            [_webView loadHTMLString:body baseURL:nil];
        }else{
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            [_webView loadFileURL:fileURL allowingReadAccessToURL:[NSURL fileURLWithPath:filePath]];
        }
    }
}

-(void)close{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)refresh{
    [self loadFile:loadUrl];
}
@end
