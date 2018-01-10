//
//  ViewController.m
//  DLANWebServer
//
//  Created by 鲍利成 on 2017/10/24.
//  Copyright © 2017年 鲍利成. All rights reserved.
//

#import "ViewController.h"
#import "GCDWebUploader.h"
#import "PreviewViewController.h"

@interface ViewController ()<GCDWebUploaderDelegate,UITableViewDelegate,UITableViewDataSource>
{
    @private
    GCDWebUploader* _webServer;
    NSMutableArray *fileArray;
}
@property(nonatomic, strong) IBOutlet UITableView *tableView;
@property(nonatomic, strong) IBOutlet UILabel *lblDesc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSMutableArray *list = [self documentsFiles];
    fileArray = [NSMutableArray arrayWithArray:list];
    
    [_tableView setTableFooterView:[UIView new]];
    [_tableView setTableHeaderView:[UIView new]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    _webServer = [[GCDWebUploader alloc] initWithUploadDirectory:documentsPath];
    _webServer.delegate = self;
    _webServer.allowHiddenItems = YES;
    if ([_webServer start]) {
        NSLog(@"%@,%@",_webServer.bonjourServerURL, [NSString stringWithFormat:NSLocalizedString(@"GCDWebServer running locally on port %i", nil), (int)_webServer.port]);
    } else {
        NSLog(@"%@",NSLocalizedString(@"GCDWebServer not running!", nil)) ;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_webServer stop];
    _webServer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma -mark private functions
-(NSMutableArray *)documentsFiles{
    NSString *appDocDir = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] relativePath];
    NSArray *contentOfFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:appDocDir error:NULL];
    NSMutableArray *fileList = [NSMutableArray array];
    for (NSString *aPath in contentOfFolder) {
        NSLog(@"apath: %@", aPath);
        NSString * fullPath = [appDocDir stringByAppendingPathComponent:aPath];
        BOOL isDir;
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir)
        {
            [fileList addObject:aPath];
        }
    }
    return fileList;
}

-(void)refreshData
{
    if(fileArray && fileArray.count > 0){
        [fileArray removeAllObjects];
    }
    NSMutableArray *list = [self documentsFiles];
    [fileArray addObjectsFromArray:list];
    [_tableView reloadData];
}
#pragma -mark GCDWebUploaderDelegate
- (void)webUploader:(GCDWebUploader*)uploader didUploadFileAtPath:(NSString*)path {
    NSLog(@"[UPLOAD] %@", path);
    [self refreshData];
}

- (void)webUploader:(GCDWebUploader*)uploader didMoveItemFromPath:(NSString*)fromPath toPath:(NSString*)toPath {
    NSLog(@"[MOVE] %@ -> %@", fromPath, toPath);
    [self refreshData];
}

- (void)webUploader:(GCDWebUploader*)uploader didDeleteItemAtPath:(NSString*)path {
    NSLog(@"[DELETE] %@", path);
    [self refreshData];
}

- (void)webUploader:(GCDWebUploader*)uploader didCreateDirectoryAtPath:(NSString*)path {
    NSLog(@"[CREATE] %@", path);
}

- (void)webServerDidCompleteBonjourRegistration:(GCDWebServer*)server
{
    NSLog(@"请在浏览器中键入%@访问",server.bonjourServerURL);
    NSString *desc = [NSString stringWithFormat:@"请在浏览器中键入%@访问",server.bonjourServerURL];
    [_lblDesc setText:desc];
}
#pragma -mark UITableViewDelegate | UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return fileArray.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentify"];
    if (cell) {
        NSString *file = [fileArray objectAtIndex:indexPath.row];
        cell.textLabel.text = file;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *file = [fileArray objectAtIndex:indexPath.row];
    NSString *appDocDir = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] relativePath];
    NSString * fullPath = [appDocDir stringByAppendingPathComponent:file];
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir)
    {
        PreviewViewController *previewVC = [[PreviewViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:previewVC];
        [self presentViewController:nav animated:YES completion:^{
            [previewVC loadFile:fullPath];
        }];
    }
}
@end
